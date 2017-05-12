--
-- PostgreSQL database dump
--

SET client_encoding = 'SQL_ASCII';
SET check_function_bodies = false;

SET SESSION AUTHORIZATION 'postgres';

--
-- TOC entry 4 (OID 2200)
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


SET SESSION AUTHORIZATION 'test';

SET search_path = public, pg_catalog;

--
-- TOC entry 5 (OID 49254)
-- Name: user_uid_seq; Type: SEQUENCE; Schema: public; Owner: test
--

CREATE SEQUENCE user_uid_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- TOC entry 6 (OID 49256)
-- Name: user; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE "user" (
    uid integer DEFAULT nextval('user_uid_seq'::text) NOT NULL,
    name character varying(40) NOT NULL,
    forename character varying(40) NOT NULL,
    street character varying(40) NOT NULL,
    zip integer NOT NULL,
    town character varying(40) NOT NULL,
    email character varying(40) NOT NULL,
    phone character varying(15)[] DEFAULT '{"",""}'::character varying[],
    birthday date NOT NULL,
    newsletter boolean DEFAULT true
);


--
-- TOC entry 10 (OID 49264)
-- Name: login; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE login (
    uid integer DEFAULT currval('user_uid_seq'::text) NOT NULL,
    username character varying(30) DEFAULT '-'::character varying NOT NULL,
    "password" character varying(30) DEFAULT '-'::character varying NOT NULL
);


--
-- TOC entry 13 (OID 49271)
-- Name: column_info; Type: VIEW; Schema: public; Owner: test
--

CREATE VIEW column_info AS
    SELECT relname, attname, atttypmod, attnotnull, typname, adsrc, description FROM ((((pg_class LEFT JOIN pg_attribute ON ((pg_class.relfilenode = pg_attribute.attrelid))) LEFT JOIN pg_type ON ((atttypid = pg_type.oid))) LEFT JOIN pg_attrdef ON (((attrelid = pg_attrdef.adrelid) AND (attnum = pg_attrdef.adnum)))) LEFT JOIN pg_description ON (((attrelid = pg_description.objoid) AND (attnum = pg_description.objsubid)))) WHERE (((((((attname <> 'tableoid'::name) AND (attname <> 'oid'::name)) AND (attname <> 'ctid'::name)) AND (attname <> 'xmax'::name)) AND (attname <> 'xmin'::name)) AND (attname <> 'cmax'::name)) AND (attname <> 'cmin'::name)) ORDER BY attnum;


--
-- TOC entry 14 (OID 49311)
-- Name: user_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (uid);


--
-- TOC entry 15 (OID 49313)
-- Name: login_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY login
    ADD CONSTRAINT login_pkey PRIMARY KEY (uid);


--
-- TOC entry 16 (OID 49315)
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY login
    ADD CONSTRAINT "$1" FOREIGN KEY (uid) REFERENCES "user"(uid) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


SET SESSION AUTHORIZATION 'postgres';

--
-- TOC entry 3 (OID 2200)
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'Standard public schema';


SET SESSION AUTHORIZATION 'test';

--
-- TOC entry 7 (OID 49256)
-- Name: COLUMN "user".zip; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON COLUMN "user".zip IS 'ERROR=digitonly;';


--
-- TOC entry 8 (OID 49256)
-- Name: COLUMN "user".email; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON COLUMN "user".email IS 'ERROR=rfc822;';


--
-- TOC entry 9 (OID 49256)
-- Name: COLUMN "user".phone; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON COLUMN "user".phone IS 'display_as={{,}};ERROR_IN={{{not_null,digitonly},{not_null,digitonly}}};SUBTITLE={{,/}};SIZE={{5,10}};';


--
-- TOC entry 11 (OID 49264)
-- Name: COLUMN login.username; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON COLUMN login.username IS 'ERROR={{regex,"must only contain A-Z, a-z and 0-9","^[A-Za-z0-9]+$"},unique,dbsql_unique};';


--
-- TOC entry 12 (OID 49264)
-- Name: COLUMN login."password"; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON COLUMN login."password" IS 'TYPE=password;VALUE=;ERROR={{regex,"must have more than 4 chars",".{5,}"}};';


