CREATE SCHEMA enum;


ALTER SCHEMA enum OWNER TO postgres;


CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO "MAPLAT_Server";

SET search_path = public, pg_catalog;



CREATE TYPE commands_enum AS ENUM (
    'VACUUM_ANALYZE',
    'VACUUM_FULL',
    'ANALYZE_TABLE',
    'REINDEX_TABLE',
    'REINDEX_ALL_TABLES',
    'BACKUP',
    'CALCULATE_STATS',
    'NOP_OK',
    'NOP_FAIL',
    'VACUUM_ANALYZE_TABLE'
);


ALTER TYPE public.commands_enum OWNER TO postgres;


CREATE TYPE doctype_enum AS ENUM (
    'Word',
    'Spreadsheet'
);


ALTER TYPE public.doctype_enum OWNER TO "MAPLAT_Server";


CREATE TYPE errors_enum AS ENUM (
    'COMMAND',
    'CONFIGURATION',
    'OTHER',
    'DIR_CLEANER'
);


ALTER TYPE public.errors_enum OWNER TO "MAPLAT_Server";


SET search_path = public, pg_catalog;


CREATE FUNCTION documents_search_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.english_tsearch :=
     setweight(to_tsvector('pg_catalog.english', coalesce(new.filename,'')), 'A') ||
     setweight(to_tsvector('pg_catalog.english', coalesce(new.txtcontent,'')), 'D');
  new.german_tsearch :=
     setweight(to_tsvector('pg_catalog.german', coalesce(new.filename,'')), 'A') ||
     setweight(to_tsvector('pg_catalog.german', coalesce(new.txtcontent,'')), 'D');   
  return new;
end
$$;


ALTER FUNCTION public.documents_search_trigger() OWNER TO "MAPLAT_Server";


CREATE FUNCTION merge_users_settings(key_username text, key_settingname text, data text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    LOOP
        -- first try to update the key
        UPDATE users_settings SET encoded_data = data WHERE username = key_username AND name = key_settingname;
        IF found THEN
            RETURN;
        END IF;
        -- not there, so try to insert the key
        -- if someone else inserts the same key concurrently,
        -- we could get a unique-key failure
        BEGIN
            INSERT INTO users_settings (username, name, encoded_data) VALUES (key_username, key_settingname, data);
            RETURN;
        EXCEPTION WHEN unique_violation THEN
            -- do nothing, and loop to try the UPDATE again
        END;
    END LOOP;
END;
$$;


ALTER FUNCTION public.merge_users_settings(key_username text, key_settingname text, data text) OWNER TO postgres;

CREATE TABLE commandqueue (
    id integer NOT NULL,
    command commands_enum NOT NULL,
    arguments text[],
    queuetime timestamp without time zone DEFAULT now() NOT NULL,
    starttime timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.commandqueue OWNER TO postgres;


CREATE SEQUENCE commandqueue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.commandqueue_id_seq OWNER TO postgres;


ALTER SEQUENCE commandqueue_id_seq OWNED BY commandqueue.id;



CREATE TABLE documents (
    id integer NOT NULL,
    doctype doctype_enum NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    updated timestamp without time zone DEFAULT now() NOT NULL,
    filename text NOT NULL,
    username text NOT NULL,
    is_public boolean DEFAULT false NOT NULL,
    content text,
    txtcontent text DEFAULT ''::text NOT NULL,
    english_tsearch tsvector,
    german_tsearch tsvector
);


ALTER TABLE public.documents OWNER TO "MAPLAT_Server";


CREATE SEQUENCE documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.documents_id_seq OWNER TO "MAPLAT_Server";


ALTER SEQUENCE documents_id_seq OWNED BY documents.id;



CREATE TABLE errors (
    error_id integer NOT NULL,
    reporttime timestamp without time zone DEFAULT now() NOT NULL,
    error_type errors_enum NOT NULL,
    description text NOT NULL
);


ALTER TABLE public.errors OWNER TO "MAPLAT_Server";


CREATE SEQUENCE errors_error_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.errors_error_id_seq OWNER TO "MAPLAT_Server";


ALTER SEQUENCE errors_error_id_seq OWNED BY errors.error_id;



CREATE TABLE maplat_patchlevel (
    id integer NOT NULL,
    patchlevel numeric(5,0) NOT NULL,
    description text NOT NULL,
    patchtime timestamp without time zone DEFAULT now()
);


ALTER TABLE public.maplat_patchlevel OWNER TO "MAPLAT_Server";


CREATE SEQUENCE maplat_patchlevel_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.maplat_patchlevel_id_seq OWNER TO "MAPLAT_Server";


ALTER SEQUENCE maplat_patchlevel_id_seq OWNED BY maplat_patchlevel.id;


CREATE TABLE users (
    username text NOT NULL,
    password_sha1 text NOT NULL,
    password_md5 text NOT NULL,
    is_admin boolean DEFAULT false NOT NULL,
    email_addr text DEFAULT ''::text NOT NULL,
    has_world boolean DEFAULT false NOT NULL,
    has_devtest boolean DEFAULT false NOT NULL
)
WITH (fillfactor=50);


ALTER TABLE public.users OWNER TO "MAPLAT_Server";


CREATE TABLE users_settings (
    username text NOT NULL,
    name text NOT NULL,
    encoded_data text NOT NULL
)
WITH (fillfactor=30);


ALTER TABLE public.users_settings OWNER TO "MAPLAT_Server";


ALTER TABLE commandqueue ALTER COLUMN id SET DEFAULT nextval('commandqueue_id_seq'::regclass);



ALTER TABLE documents ALTER COLUMN id SET DEFAULT nextval('documents_id_seq'::regclass);



ALTER TABLE errors ALTER COLUMN error_id SET DEFAULT nextval('errors_error_id_seq'::regclass);




ALTER TABLE maplat_patchlevel ALTER COLUMN id SET DEFAULT nextval('maplat_patchlevel_id_seq'::regclass);


ALTER TABLE ONLY commandqueue
    ADD CONSTRAINT commandqueue_pk PRIMARY KEY (id);



ALTER TABLE ONLY documents
    ADD CONSTRAINT documents_pk PRIMARY KEY (id);


ALTER TABLE ONLY maplat_patchlevel
    ADD CONSTRAINT maplat_patchlevel_pkey PRIMARY KEY (id);



ALTER TABLE ONLY maplat_patchlevel
    ADD CONSTRAINT maplat_patchlevel_uk UNIQUE (patchlevel);



ALTER TABLE ONLY errors
    ADD CONSTRAINT rbserrors_pk PRIMARY KEY (error_id);



ALTER TABLE ONLY users
    ADD CONSTRAINT rbsusers_pk PRIMARY KEY (username);



ALTER TABLE ONLY users_settings
    ADD CONSTRAINT rbsusers_settings_pk PRIMARY KEY (username, name);




CREATE INDEX documents_detxtidx ON documents USING gin (german_tsearch);



CREATE INDEX documents_entxtidx ON documents USING gin (english_tsearch);




CREATE INDEX documents_idx1 ON documents USING btree (username, is_public);



CREATE INDEX documents_idx2 ON documents USING btree (filename);


CREATE TRIGGER documents_search_update
    BEFORE INSERT OR UPDATE ON documents
    FOR EACH ROW
    EXECUTE PROCEDURE documents_search_trigger();



ALTER TABLE ONLY documents
    ADD CONSTRAINT "documents/users" FOREIGN KEY (username) REFERENCES users(username) ON UPDATE CASCADE ON DELETE CASCADE;




ALTER TABLE ONLY users_settings
    ADD CONSTRAINT rbsusers_settings_fk1 FOREIGN KEY (username) REFERENCES users(username) ON UPDATE CASCADE ON DELETE CASCADE;



REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


CREATE TABLE memcachedb
(
  mckey text NOT NULL,
  mcdata text NOT NULL,
  CONSTRAINT memcachedb_pk PRIMARY KEY (mckey) USING INDEX TABLESPACE "RBS_INDEX1"
)
WITH (
  FILLFACTOR=20, 
  OIDS=FALSE
)
TABLESPACE "RBS_DATA";
ALTER TABLE memcachedb OWNER TO "MAPLAT_Server";


CREATE OR REPLACE FUNCTION merge_memcachedb(mc_key text, mc_data text)
  RETURNS void AS
$BODY$
BEGIN
    LOOP
        -- first try to update the key
        UPDATE memcachedb SET mcdata = mc_data WHERE mckey = mc_key;
        IF found THEN
            RETURN;
        END IF;
        -- not there, so try to insert the key
        -- if someone else inserts the same key concurrently,
        -- we could get a unique-key failure
        BEGIN
            INSERT INTO memcachedb (mckey, mcdata) VALUES (mc_key, mc_data);
            RETURN;
        EXCEPTION WHEN unique_violation THEN
            -- do nothing, and loop to try the UPDATE again
        END;
    END LOOP;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION merge_memcachedb(text, text) OWNER TO "MAPLAT_Server";

