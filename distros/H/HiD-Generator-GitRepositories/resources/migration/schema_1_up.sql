CREATE TABLE repository (
    reponame TEXT,
    dir      TEXT,
    lastchange INTEGER,
    description TEXT
);

CREATE TABLE repository_languages (
    reponame TEXT,
    language TEXT
);

CREATE TABLE repository_tags (
    reponame TEXT,
    tag TEXT
);
