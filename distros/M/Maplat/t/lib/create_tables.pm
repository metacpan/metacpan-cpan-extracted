
use strict;
use warnings;

package CreateTables;

sub getStmts {
    
    my @stmts = (
        "CREATE SCHEMA enum",
        "CREATE PROCEDURAL LANGUAGE plpgsql",
        "   SET search_path = public, pg_catalog",
        "   CREATE TYPE commands_enum AS ENUM ( 'VACUUM_ANALYZE', 'VACUUM_FULL', 'ANALYZE_TABLE', 'REINDEX_TABLE', 'REINDEX_ALL_TABLES', 'BACKUP', 'CALCULATE_STATS', 'NOP_OK', 'NOP_FAIL', 'VACUUM_ANALYZE_TABLE' )",
        "    CREATE TYPE doctype_enum AS ENUM ( 'Word', 'Spreadsheet' )",
        "    CREATE TYPE errors_enum AS ENUM ( 'COMMAND', 'CONFIGURATION', 'OTHER', 'DIR_CLEANER' )",
        "    SET search_path = public, pg_catalog",
        "  CREATE TABLE commandqueue ( id integer NOT NULL, command commands_enum NOT NULL, arguments text[], queuetime timestamp without time zone DEFAULT now() NOT NULL, starttime timestamp without time zone DEFAULT now() NOT NULL )",
        "    CREATE SEQUENCE commandqueue_id_seq START WITH 1 INCREMENT BY 1 NO MAXVALUE NO MINVALUE CACHE 1",
        "    ALTER SEQUENCE commandqueue_id_seq OWNED BY commandqueue.id",
        "   CREATE TABLE documents ( id integer NOT NULL, doctype doctype_enum NOT NULL, created timestamp without time zone DEFAULT now() NOT NULL, updated timestamp without time zone DEFAULT now() NOT NULL, filename text NOT NULL, username text NOT NULL, is_public boolean DEFAULT false NOT NULL, content text, txtcontent text DEFAULT ''::text NOT NULL, english_tsearch tsvector, german_tsearch tsvector )",
        "    CREATE SEQUENCE documents_id_seq START WITH 1 INCREMENT BY 1 NO MAXVALUE NO MINVALUE CACHE 1",
        "    ALTER SEQUENCE documents_id_seq OWNED BY documents.id",
        "   CREATE TABLE errors ( error_id integer NOT NULL, reporttime timestamp without time zone DEFAULT now() NOT NULL, error_type errors_enum NOT NULL, description text NOT NULL )",
        "    CREATE SEQUENCE errors_error_id_seq START WITH 1 INCREMENT BY 1 NO MAXVALUE NO MINVALUE CACHE 1",
        "    ALTER SEQUENCE errors_error_id_seq OWNED BY errors.error_id",
        "   CREATE TABLE maplat_patchlevel ( id integer NOT NULL, patchlevel numeric(5,0) NOT NULL, description text NOT NULL, patchtime timestamp without time zone DEFAULT now() )",
        "    CREATE SEQUENCE maplat_patchlevel_id_seq START WITH 1 INCREMENT BY 1 NO MAXVALUE NO MINVALUE CACHE 1",
        "    ALTER SEQUENCE maplat_patchlevel_id_seq OWNED BY maplat_patchlevel.id",
        "  CREATE TABLE users ( username text NOT NULL, password_sha1 text NOT NULL, password_md5 text NOT NULL, is_admin boolean DEFAULT false NOT NULL, email_addr text DEFAULT ''::text NOT NULL, has_world boolean DEFAULT false NOT NULL, has_devtest boolean DEFAULT false NOT NULL ) WITH (fillfactor=50)",
        "    CREATE TABLE users_settings ( username text NOT NULL, name text NOT NULL, encoded_data text NOT NULL ) WITH (fillfactor=30)",
        "    ALTER TABLE commandqueue ALTER COLUMN id SET DEFAULT nextval('commandqueue_id_seq'::regclass)",
        "   ALTER TABLE documents ALTER COLUMN id SET DEFAULT nextval('documents_id_seq'::regclass)",
        "   ALTER TABLE errors ALTER COLUMN error_id SET DEFAULT nextval('errors_error_id_seq'::regclass)",
        "    ALTER TABLE maplat_patchlevel ALTER COLUMN id SET DEFAULT nextval('maplat_patchlevel_id_seq'::regclass)",
        "  ALTER TABLE ONLY commandqueue ADD CONSTRAINT commandqueue_pk PRIMARY KEY (id)",
        "   ALTER TABLE ONLY documents ADD CONSTRAINT documents_pk PRIMARY KEY (id)",
        "  ALTER TABLE ONLY maplat_patchlevel ADD CONSTRAINT maplat_patchlevel_pkey PRIMARY KEY (id)",
        "   ALTER TABLE ONLY maplat_patchlevel ADD CONSTRAINT maplat_patchlevel_uk UNIQUE (patchlevel)",
        "   ALTER TABLE ONLY errors ADD CONSTRAINT errors_pk PRIMARY KEY (error_id)",
        "   ALTER TABLE ONLY users ADD CONSTRAINT users_pk PRIMARY KEY (username)",
        "   ALTER TABLE ONLY users_settings ADD CONSTRAINT users_settings_pk PRIMARY KEY (username, name)",
        "    CREATE INDEX documents_detxtidx ON documents USING gin (german_tsearch)",
        "   CREATE INDEX documents_entxtidx ON documents USING gin (english_tsearch)",
        "    CREATE INDEX documents_idx1 ON documents USING btree (username, is_public)",
        "   CREATE INDEX documents_idx2 ON documents USING btree (filename)",
        "  ALTER TABLE ONLY documents ADD CONSTRAINT \"documents/users\" FOREIGN KEY (username) REFERENCES users(username) ON UPDATE CASCADE ON DELETE CASCADE",
        "  ALTER TABLE ONLY users_settings ADD CONSTRAINT users_settings_fk1 FOREIGN KEY (username) REFERENCES users(username) ON UPDATE CASCADE ON DELETE CASCADE",
    );

return @stmts;
}
1;
