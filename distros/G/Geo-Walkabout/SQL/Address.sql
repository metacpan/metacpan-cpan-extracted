DROP TABLE Address_Range;

CREATE TABLE Address_Range (
    TLID    INTEGER     NOT NULL REFERENCES Line_Feature,

    /* From, To and End are all keywords :( */
    Start_Addr   DECIMAL(11,0)    NOT NULL      CHECK( Start_Addr > 0 ),
    End_Addr     DECIMAL(11,0)    NOT NULL      CHECK( End_Addr   > 0 ),

    Side    CHAR(1)     NOT NULL        CHECK( Side = 'R' OR Side = 'L' )
);

CREATE INDEX TLID_Address ON Address_Range (TLID);
