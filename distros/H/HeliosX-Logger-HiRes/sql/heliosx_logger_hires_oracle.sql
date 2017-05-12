-- Log Table
CREATE TABLE helios_log_entry_tb
(
    logid NUMBER(24,0) PRIMARY KEY NOT NULL,
    log_time DECIMAL(32,6) NOT NULL,
    host VARCHAR2(64),
    pid NUMBER(10,0),
    jobid NUMBER(24,0),
    jobtypeid NUMBER(24,0),
    service VARCHAR2(128),
    priority VARCHAR2(20),
    message VARCHAR2(4000)
);

CREATE INDEX helios_let_lt_idx ON helios_log_entry_tb (log_time);
CREATE INDEX helios_let_lt_lid_idx ON helios_log_entry_tb (log_time, logid);

CREATE SEQUENCE helios_log_entry_tb_logid_seq
MINVALUE 1
MAXVALUE 999999999999999999999999
INCREMENT BY 1
START WITH 2
CACHE 2000
NOORDER
NOCYCLE;

CREATE OR REPLACE TRIGGER helios_let_lid_trg
BEFORE INSERT OR UPDATE
ON helios_log_entry_tb
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
DECLARE
v_newVal NUMBER(12) := 0;
v_incval NUMBER(12) := 0;
BEGIN
  IF INSERTING AND :new.logid IS NULL THEN
    SELECT  helios_log_entry_tb_logid_seq.nextval INTO v_newVal FROM DUAL;
    -- If this is the first time this table have been inserted into (sequence == 1)
    IF v_newVal = 1 THEN
      --get the max indentity value from the table
      SELECT NVL(max(logid),0) INTO v_newVal FROM helios_log_entry_tb;
      v_newVal := v_newVal + 1;
      --set the sequence to that value
      LOOP
           EXIT WHEN v_incval>=v_newVal;
           SELECT helios_log_entry_tb_logid_seq.nextval INTO v_incval FROM dual;
      END LOOP;
    END IF;
   :new.logid := v_newVal;
  END IF;
END;
/
ALTER TRIGGER helios_let_lid_trg ENABLE;
