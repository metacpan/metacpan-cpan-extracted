-- Error Table
CREATE TABLE error (
    error_time NUMBER(10,0) NOT NULL, 
    jobid NUMBER(24,0) NOT NULL, 
    message VARCHAR2(255), 
    funcid NUMBER(10,0) DEFAULT '0' NOT NULL
);

CREATE INDEX error_et_idx ON error (error_time); 
CREATE INDEX error_fid_et_idx ON error (funcid, error_time);
CREATE INDEX error_jid_idx ON error (jobid); 


-- Exitstatus Table
CREATE TABLE exitstatus ( 
    jobid NUMBER(24,0) PRIMARY KEY NOT NULL, 
    funcid NUMBER(10,0) DEFAULT '0' NOT NULL, 
    status NUMBER(5,0),
    completion_time NUMBER(10,0), 
    delete_after NUMBER(10,0)
);

CREATE INDEX exitstatus_da_idx ON exitstatus (delete_after); 
CREATE INDEX exitstatus_funcid_idx ON exitstatus (funcid); 


-- Funcmap Table
CREATE TABLE funcmap (
    funcid NUMBER(10,0) PRIMARY KEY NOT NULL, 
    funcname VARCHAR2(255) NOT NULL
);

CREATE UNIQUE INDEX funcmap_fn_idx ON funcmap (funcname); 

CREATE SEQUENCE funcmap_funcid_seq
MINVALUE 1
MAXVALUE 999999999999999999999999
INCREMENT BY 1
START WITH 2
CACHE 2000
NOORDER
NOCYCLE;

CREATE OR REPLACE TRIGGER funcmap_funcid_trg BEFORE INSERT OR UPDATE ON funcmap
FOR EACH ROW
DECLARE
v_newVal NUMBER(12) := 0;
v_incval NUMBER(12) := 0;
BEGIN
    IF INSERTING AND :new.funcid IS NULL THEN
        SELECT funcmap_funcid_seq.nextval INTO v_newVal FROM DUAL;
        -- If this is the first time this table have been inserted into (sequence == 1)
        IF v_newVal = 1 THEN
            --get the max indentity value from the table
            SELECT NVL(max(funcid),0) INTO v_newVal FROM funcmap;
            v_newVal := v_newVal + 1;
            --set the sequence to that value
            LOOP
                EXIT WHEN v_incval>=v_newVal;
                SELECT funcmap_funcid_seq.nextval INTO v_incval FROM dual;
            END LOOP;
        END IF;
        --used to emulate LAST_INSERT_ID()
        --mysql_utilities.identity := v_newVal;
        -- assign the value from the sequence to emulate the identity column
        :new.funcid := v_newVal;
    END IF;
END;
/
ALTER TRIGGER funcmap_funcid_trg ENABLE;


-- Job Table
CREATE TABLE job (
    jobid NUMBER(24,0) PRIMARY KEY NOT NULL, 
    funcid NUMBER(10,0) NOT NULL, 
    arg BLOB, 
    uniqkey VARCHAR2(255),
    insert_time NUMBER(10,0), 
    run_after NUMBER(10,0) NOT NULL, 
    grabbed_until NUMBER(10,0) NOT NULL, 
    priority NUMBER(5,0), 
    coalesce VARCHAR2(255)
);

CREATE INDEX job_fid_c_idx ON job (funcid, coalesce);
CREATE INDEX job_fid_ra_idx ON job (funcid, run_after); 
CREATE INDEX job_fid_uk_idx ON job (funcid, uniqkey);

CREATE SEQUENCE job_jobid_seq
MINVALUE 1
MAXVALUE 999999999999999999999999 
INCREMENT BY 1 
START WITH 2 
CACHE 2000 
NOORDER
NOCYCLE;

CREATE OR REPLACE TRIGGER job_jobid_trg BEFORE INSERT OR UPDATE ON job
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
DECLARE
    v_newVal NUMBER(12) := 0;
    v_incval NUMBER(12) := 0;
BEGIN
    IF INSERTING AND :new.jobid IS NULL THEN
        SELECT  job_jobid_SEQ.NEXTVAL INTO v_newVal FROM DUAL;
        -- If this is the first time this table have been inserted into (sequence == 1)
        IF v_newVal = 1 THEN
            --get the max indentity value from the table
            SELECT NVL(max(jobid),0) INTO v_newVal FROM job;
            v_newVal := v_newVal + 1;
            --set the sequence to that value
            LOOP
                EXIT WHEN v_incval>=v_newVal;
                SELECT job_jobid_SEQ.nextval INTO v_incval FROM dual;
            END LOOP;
        END IF;
        --used to emulate LAST_INSERT_ID()
        --mysql_utilities.identity := v_newVal;
        -- assign the value from the sequence to emulate the identity column
        :new.jobid := v_newVal;
    END IF;
END;
/
ALTER TRIGGER job_jobid_trg ENABLE;


-- Note Table
CREATE TABLE note (
    jobid NUMBER(24,0) NOT NULL, 
    notekey VARCHAR2(255) NOT NULL, 
    value BLOB,
    PRIMARY KEY(jobid, notekey)
);


-- Helios Class Map
CREATE TABLE helios_class_map (
    job_type VARCHAR2(32), 
    job_class VARCHAR2(64)
);


-- Helios Job History Table
CREATE TABLE helios_job_history_tb (
    jobid NUMBER(24,0) NOT NULL, 
    funcid NUMBER(10,0) NOT NULL, 
    arg VARCHAR2(4000), 
    uniqkey VARCHAR2(255), 
    insert_time NUMBER(10,0), 
    run_after NUMBER(10,0) NOT NULL, 
    grabbed_until NUMBER(10,0) NOT NULL, 
    priority NUMBER(5,0), 
    coalesce VARCHAR2(255), 
    complete_time NUMBER(10,0) NOT NULL, 
    exitstatus NUMBER(5,0)
);

CREATE INDEX helios_jht_ct_idx ON helios_job_history_tb (complete_time);
CREATE INDEX helios_jht_jid_idx ON helios_job_history_tb (jobid); 


-- Helios Log Table
CREATE TABLE helios_log_tb (
    log_time NUMBER(10,0) NOT NULL, 
    host VARCHAR2(64), 
    process_id NUMBER(10,0), 
    jobid NUMBER(24,0), 
    funcid NUMBER(10,0), 
    job_class VARCHAR2(64), 
    priority VARCHAR2(20), 
    message VARCHAR2(4000)
);

CREATE INDEX helios_lt_lt_idx ON helios_log_tb (log_time);


-- Helios Params Table
CREATE TABLE helios_params_tb (
    host VARCHAR2(64), 
    worker_class VARCHAR2(64), 
    param VARCHAR2(64), 
    value VARCHAR2(128)
);


-- Helios Worker Registry Table
CREATE TABLE helios_worker_registry_tb (
    register_time NUMBER(10,0) NOT NULL, 
    start_time NUMBER(10,0), 
    worker_class VARCHAR2(64),
    worker_version VARCHAR2(10),
    host VARCHAR2(64),
    process_id NUMBER(10,0)
);

