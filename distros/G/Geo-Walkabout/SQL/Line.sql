DROP TABLE Line_Feature;

/* Line is a PostgreSQL type */
CREATE TABLE Line_Feature (
    TLID        INTEGER         PRIMARY KEY,

    FeDirP      CHAR(2),
    FeName      VARCHAR(30),
    FeType      CHAR(4),
    FeDirS      CHAR(2),

    /* 5 digit zip codes + 4, left and right sides */
    ZipL        DECIMAL(5,0)    CHECK ( ZipL  > 0 ),
    Zip4L       DECIMAL(4,0)    CHECK ( Zip4L > 0 ),
    ZipR        DECIMAL(5,0)    CHECK ( ZipR  > 0 ),
    Zip4R       DECIMAL(4,0)    CHECK ( Zip4R > 0 ),

    Chain_Start POINT           NOT NULL,
    Chain_End   POINT           NOT NULL,

/*    Chain_Length        FLOAT   NOT NULL,  */
    
    Chain       PATH            NOT NULL
);


CREATE INDEX FeName ON Line_Feature (FeName);
CREATE INDEX ZipL   ON Line_Feature (ZipL);
CREATE INDEX ZipR   ON Line_Feature (ZipR);