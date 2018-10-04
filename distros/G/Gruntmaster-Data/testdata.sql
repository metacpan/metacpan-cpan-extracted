CREATE OR REPLACE FUNCTION tm() RETURNS BIGINT IMMUTABLE LANGUAGE SQL AS $$
	SELECT EXTRACT(epoch FROM NOW())::bigint
$$;

TRUNCATE users, contests, problems, jobs RESTART IDENTITY CASCADE;

-- USERS

INSERT INTO users (id, admin) VALUES ('MGV', TRUE);
INSERT INTO users (id, admin) VALUES ('nobody', FALSE);

-- CONTESTS

ALTER TABLE contests ALTER owner SET DEFAULT 'MGV';

INSERT INTO contests (id, start, stop, name) VALUES ('fc', tm() - 2000, tm() - 1000, 'Finished contest');
INSERT INTO contests (id, start, stop, name) VALUES ('rc', tm() - 1000, tm() + 1000, 'Running contest');
INSERT INTO contests (id, start, stop, name) VALUES ('pc', tm() + 1000, tm() + 2000, 'Pending contest');

-- PROBLEMS

ALTER TABLE problems ALTER generator SET DEFAULT 'Undef',
                     ALTER runner    SET DEFAULT 'File',
                     ALTER judge     SET DEFAULT 'Absolute',
                     ALTER level     SET DEFAULT 'beginner',
                     ALTER value     SET DEFAULT 100,
                     ALTER owner     SET DEFAULT 'MGV',
                     ALTER statement SET DEFAULT 'Sample Text',
                     ALTER solution  SET DEFAULT 'Sample Text',
                     ALTER testcnt   SET DEFAULT 1,
                     ALTER timeout   SET DEFAULT 1;

INSERT INTO problems (id, name, private) VALUES ('fca', 'FC problem A', FALSE);
INSERT INTO problems (id, name, private) VALUES ('rca', 'RC problem A', TRUE);
INSERT INTO problems (id, name, private) VALUES ('pca', 'PC problem A', TRUE);
INSERT INTO problems (id, name, private) VALUES ('arc', 'Problem in archive', FALSE);
INSERT INTO problems (id, name, private) VALUES ('prv', 'Private problem', TRUE);

INSERT INTO contest_problems (contest, problem) VALUES ('fc', 'fca');
INSERT INTO contest_problems (contest, problem) VALUES ('rc', 'rca');
INSERT INTO contest_problems (contest, problem) VALUES ('pc', 'pca');

INSERT INTO limits (problem, format, timeout) VALUES ('arc', 'C', 0.1);
INSERT INTO limits (problem, format, timeout) VALUES ('arc', 'CPP', 0.1);

-- JOBS

ALTER TABLE jobs ALTER date        SET DEFAULT tm() - 1500,
                 ALTER errors      SET DEFAULT 'Errors here',
                 ALTER extension   SET DEFAULT 'pl',
                 ALTER format      SET DEFAULT 'PERL',
                 ALTER result      SET DEFAULT 0,
                 ALTER result_text SET DEFAULT 'Accepted',
                 ALTER results     SET DEFAULT '[]',
                 ALTER source      SET DEFAULT 'print "Hello, world!"',
                 ALTER owner       SET DEFAULT 'nobody';

INSERT INTO jobs (contest, problem, owner) VALUES ('fc', 'fca', 'MGV');
INSERT INTO jobs (contest, problem, result, result_text, date) VALUES ('fc', 'fca', 1, 'Wrong Answer', tm() - 1600);
INSERT INTO jobs (contest, problem) VALUES ('fc', 'fca');
INSERT INTO jobs (problem, date) VALUES ('fca', tm() - 500);
INSERT INTO jobs (problem, date) VALUES ('arc', tm() - 100);
INSERT INTO jobs (problem, private, owner) VALUES ('pca', TRUE, 'MGV');
INSERT INTO jobs (problem, private, owner, result, result_text, results) VALUES ('prv', TRUE, 'MGV', NULL, NULL, NULL);
