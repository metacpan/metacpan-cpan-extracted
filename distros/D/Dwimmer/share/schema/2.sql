--- tables for domains

CREATE TABLE host (
    id      INTEGER PRIMARY KEY,
    name    VARCHAR(100) UNIQUE NOT NULL,
    main    INTEGER NOT NULL,
    FOREIGN KEY (main) REFERENCES site(id)
);
PRAGMA user_version=2;
