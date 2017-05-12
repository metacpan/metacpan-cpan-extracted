CREATE TABLE "identificators" (
    "id"    SERIAL PRIMARY KEY,
    "jid"   VARCHAR(255) NOT NULL,

    UNIQUE("jid")
);

CREATE TABLE "messages" (
    "sender"    INTEGER
        REFERENCES "identificators"("id"),
    "sender_resource" VARCHAR(255) DEFAULT '',

    "recipient" INTEGER
        REFERENCES "identificators"("id"),
    "recipient_resource" VARCHAR(255) DEFAULT '',

    "id"        VARCHAR(255) DEFAULT NULL,
    "type"      VARCHAR(255) DEFAULT NULL,
    "body"      TEXT,
    "thread"    VARCHAR(255) DEFAULT NULL,

    "timestamp" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
