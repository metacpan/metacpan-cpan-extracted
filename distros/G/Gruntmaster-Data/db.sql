CREATE TABLE IF NOT EXISTS users (
	id         TEXT    PRIMARY KEY,
	passphrase TEXT,   -- NOT NULL,
	admin      BOOLEAN NOT NULL DEFAULT FALSE,
	name       TEXT,  -- NOT NULL,
	email      TEXT,  -- NOT NULL,
	phone      TEXT,  -- NOT NULL,
	town       TEXT,  -- NOT NULL,
	university TEXT,  -- NOT NULL,
	level      TEXT,  -- NOT NULL,
	country    TEXT,
	lastjob    BIGINT,
	since      BIGINT DEFAULT CAST(EXTRACT(epoch from now()) AS bigint)
);

CREATE TABLE IF NOT EXISTS contests (
	id          TEXT PRIMARY KEY,
	name        TEXT NOT NULL,
	editorial   TEXT,
	description TEXT,
	start       INT  NOT NULL,
	stop        INT  NOT NULL,
	owner       TEXT NOT NULL REFERENCES users ON DELETE CASCADE,
	CONSTRAINT  positive_duration CHECK (stop > start)
);

CREATE TABLE IF NOT EXISTS contest_status (
	contest TEXT NOT NULL REFERENCES contests ON DELETE CASCADE,
	owner   TEXT NOT NULL REFERENCES users ON DELETE CASCADE,
	score   INT  NOT NULL,
	rank    INT  NOT NULL,

	PRIMARY KEY (owner, contest)
);

CREATE TABLE IF NOT EXISTS problems (
	id        TEXT      PRIMARY KEY,
	author    TEXT,
	writer    TEXT,
	generator TEXT    NOT NULL,
	judge     TEXT    NOT NULL,
	level     TEXT    NOT NULL,
	name      TEXT    NOT NULL,
	olimit    INT,
	owner     TEXT    NOT NULL REFERENCES users ON DELETE CASCADE,
	private   BOOLEAN NOT NULL DEFAULT FALSE,
	runner    TEXT    NOT NULL,
	solution  TEXT ,
	statement TEXT    NOT NULL,
	testcnt   INT     NOT NULL,
	precnt    INT,
	tests     TEXT,
	timeout   REAL    NOT NULL,
	value     INT     NOT NULL,
	genformat TEXT,
	gensource TEXT,
	verformat TEXT,
	versource TEXT
);

CREATE TABLE IF NOT EXISTS contest_problems (
	contest TEXT REFERENCES contests ON DELETE CASCADE,
	problem TEXT NOT NULL REFERENCES problems ON DELETE CASCADE,
	PRIMARY KEY (contest, problem)
);

CREATE TABLE IF NOT EXISTS jobs (
	id          SERIAL  PRIMARY KEY,
	contest     TEXT    REFERENCES contests ON DELETE CASCADE,
	daemon      TEXT,
	date        BIGINT  NOT NULL DEFAULT CAST(EXTRACT(epoch from now()) AS bigint),
	errors      TEXT,
	extension   TEXT    NOT NULL,
	format      TEXT    NOT NULL,
	private     BOOLEAN NOT NULL DEFAULT FALSE,
	problem     TEXT    NOT NULL REFERENCES problems ON DELETE CASCADE,
	reference   INT,
	result      INT,
	result_text TEXT,
	results     TEXT,
	source      TEXT    NOT NULL,
	owner       TEXT    NOT NULL REFERENCES users ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS problem_status (
	problem TEXT    NOT NULL REFERENCES problems ON DELETE CASCADE,
	owner   TEXT    NOT NULL REFERENCES users ON DELETE CASCADE,
	job     SERIAL  NOT NULL REFERENCES jobs ON DELETE CASCADE,
	solved  BOOLEAN NOT NULL DEFAULT FALSE,

	PRIMARY KEY (owner, problem)
);

CREATE TABLE IF NOT EXISTS opens (
	contest TEXT   NOT NULL REFERENCES contests ON DELETE CASCADE,
	problem TEXT   NOT NULL REFERENCES problems ON DELETE CASCADE,
	owner   TEXT   NOT NULL REFERENCES users ON DELETE CASCADE,
	time    BIGINT NOT NULL,
	PRIMARY KEY (contest, problem, owner)
);

CREATE TABLE IF NOT EXISTS limits (
	problem TEXT NOT NULL REFERENCES problems ON DELETE CASCADE,
	format  TEXT NOT NULL,
	timeout REAL NOT NULL,
	PRIMARY KEY (problem, format)
);

COMMENT ON TABLE users            IS 'List of users';
COMMENT ON TABLE contests         IS 'List of contests';
COMMENT ON TABLE contest_status   IS 'List of (contest, user, result)';
COMMENT ON TABLE problems         IS 'List of problems';
COMMENT ON TABLE contest_problems IS 'Many-to-many bridge between contests and problems';
COMMENT ON TABLE jobs             IS 'List of jobs';
COMMENT ON TABLE problem_status   IS 'List of (problem, user, result)';
COMMENT ON TABLE opens            IS 'List of (contest, problem, user, time when user opened problem)';
COMMENT ON TABLE limits           IS 'Time limit overrides for certain problem/format pairs';

COMMENT ON COLUMN users.passphrase IS 'RFC2307-encoded passphrase';
COMMENT ON COLUMN users.name       IS 'Full name of user';
COMMENT ON COLUMN users.level      IS 'Highschool, Undergraduate, Master, Doctorate or Other';
COMMENT ON COLUMN users.lastjob    IS 'Unix time when this user last submitted a job';
COMMENT ON COLUMN users.since      IS 'Unix time when this user was created';

COMMENT ON COLUMN contests.start       IS 'Unix time when contest starts';
COMMENT ON COLUMN contests.stop        IS 'Unix time when contest ends';
COMMENT ON COLUMN contests.editorial   IS 'HTML fragment placed before the editorial';
COMMENT ON COLUMN contests.description IS 'HTML fragment placed on contest page';

COMMENT ON COLUMN problems.author    IS 'Full name(s) of problem author(s)/problemsetter(s)/tester(s)/etc';
COMMENT ON COLUMN problems.writer    IS 'Full name(s) of statement writer(s) (DEPRECATED)';
COMMENT ON COLUMN problems.generator IS 'Generator class, without the leading Gruntmaster::Daemon::Generator::';
COMMENT ON COLUMN problems.runner    IS 'Runner class, without the leading Gruntmaster::Daemon::Runner::';
COMMENT ON COLUMN problems.judge     IS 'Judge class, without the leading Gruntmaster::Daemon::Judge::';
COMMENT ON COLUMN problems.level     IS 'Problem level, one of beginner, easy, medium, hard';
COMMENT ON COLUMN problems.olimit    IS 'Output limit (in bytes)';
COMMENT ON COLUMN problems.timeout   IS 'Time limit (in seconds)';
COMMENT ON COLUMN problems.solution  IS 'Solution (HTML)';
COMMENT ON COLUMN problems.statement IS 'Statement (HTML)';
COMMENT ON COLUMN problems.testcnt   IS 'Number of tests';
COMMENT ON COLUMN problems.precnt    IS 'Number of pretests. NULL indicates full feedback.';
COMMENT ON COLUMN problems.tests     IS 'JSON array of test values for ::Runner::File';
COMMENT ON COLUMN problems.value     IS 'Problem value when used in a contest.';
COMMENT ON COLUMN problems.genformat IS 'Format (programming language) of the generator if using the Run generator';
COMMENT ON COLUMN problems.gensource IS 'Source code of generator if using the Run generator';
COMMENT ON COLUMN problems.verformat IS 'Format (programming language) of the verifier if using the Verifier runner';
COMMENT ON COLUMN problems.versource IS 'Source code of verifier if using the Verifier runner';

COMMENT ON COLUMN jobs.daemon      IS 'hostname:PID of daemon that last executed this job. NULL if never executed';
COMMENT ON COLUMN jobs.date        IS 'Unix time when job was submitted';
COMMENT ON COLUMN jobs.errors      IS 'Compiler errors';
COMMENT ON COLUMN jobs.extension   IS 'File extension of submitted program, without a leading dot';
COMMENT ON COLUMN jobs.format      IS 'Format (programming language) of submitted program';
COMMENT ON COLUMN jobs.reference   IS 'If not null, this is a reference solution that should get this result. For example, set reference=0 on jobs that should be accepted, reference=3 on jobs that should get TLE, etc';
COMMENT ON COLUMN jobs.result      IS 'Job result (integer constant from Gruntmaster::Daemon::Constants)';
COMMENT ON COLUMN jobs.result_text IS 'Job result (human-readable text)';
COMMENT ON COLUMN jobs.results     IS 'Per-test results (JSON array of hashes with keys id (test number, counting from 1), result (integer constant from Gruntmaster::Daemon::Constants), result_text (human-readable text), time (execution time in decimal seconds))';

CREATE OR REPLACE VIEW user_data AS (SELECT
	id,admin,name,town,university,country,level,lastjob
	FROM users
);

CREATE OR REPLACE VIEW user_list AS (SELECT
	dt.*,
	COALESCE(solved, 0) as solved,
	COALESCE(attempted, 0) as attempted,
	COALESCE(contests, 0) as contests
	FROM user_data dt
	LEFT JOIN (SELECT owner as id, COUNT(*) as solved FROM problem_status WHERE solved=TRUE GROUP BY owner) ps USING (id)
	LEFT JOIN (SELECT owner as id, COUNT(*) as attempted FROM problem_status WHERE solved=FALSE GROUP BY owner) pa USING (id)
	LEFT JOIN (SELECT owner as id, COUNT(*) as contests FROM contest_status GROUP BY owner) ct USING (id)
	ORDER BY solved DESC, attempted DESC, id);

CREATE OR REPLACE VIEW contest_entry AS (SELECT
	id,name,description,start,stop,owner,
	(EXTRACT(epoch from NOW()) >= start) AS started,
	(EXTRACT(epoch from NOW()) >= stop) AS finished
	FROM contests
	ORDER BY start DESC);

CREATE OR REPLACE VIEW job_entry AS (SELECT
	id,contest,date,errors,extension,format,private,problem,result,result_text,results,owner,
	LENGTH(source) AS size
	FROM jobs
	ORDER BY id DESC);
