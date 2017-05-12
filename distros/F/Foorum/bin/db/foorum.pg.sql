--
-- Table: banned_ip
--
CREATE TABLE "banned_ip" (
  "ip_id" serial NOT NULL,
  "cidr_ip" character varying(20) DEFAULT '' NOT NULL,
  "time" bigint DEFAULT '0' NOT NULL,
  PRIMARY KEY ("ip_id")
);



--
-- Table: comment
--
CREATE TABLE "comment" (
  "comment_id" serial NOT NULL,
  "reply_to" bigint DEFAULT '0' NOT NULL,
  "text" text NOT NULL,
  "post_ip" character varying(32) DEFAULT '' NOT NULL,
  "formatter" character varying(16) DEFAULT 'ubb' NOT NULL,
  "object_type" character varying(30) NOT NULL,
  "object_id" bigint DEFAULT '0' NOT NULL,
  "author_id" bigint DEFAULT '0' NOT NULL,
  "title" character varying(255) DEFAULT '' NOT NULL,
  "forum_id" bigint DEFAULT '0' NOT NULL,
  "upload_id" bigint DEFAULT '0' NOT NULL,
  "post_on" bigint DEFAULT '0' NOT NULL,
  "update_on" bigint DEFAULT '0' NOT NULL,
  PRIMARY KEY ("comment_id")
);
CREATE INDEX "comment_id" on "comment" ("comment_id");
CREATE INDEX "upload_id" on "comment" ("upload_id");
CREATE INDEX "author_id" on "comment" ("author_id");


--
-- Table: filter_word
--
CREATE TABLE "filter_word" (
  "word" character varying(64) NOT NULL,
  "type" character varying(19) DEFAULT 'username_reserved' NOT NULL,
  PRIMARY KEY ("word", "type")
);
CREATE INDEX "word" on "filter_word" ("word");


--
-- Table: forum
--
CREATE TABLE "forum" (
  "forum_id" serial NOT NULL,
  "forum_code" character varying(25) NOT NULL,
  "name" character varying(100) NOT NULL,
  "description" character varying(255) NOT NULL,
  "forum_type" character varying(16) NOT NULL,
  "policy" character varying(9) DEFAULT 'public' NOT NULL,
  "total_members" integer DEFAULT '0' NOT NULL,
  "total_topics" bigint DEFAULT '0' NOT NULL,
  "total_replies" bigint DEFAULT '0' NOT NULL,
  "status" character varying(7) DEFAULT 'healthy' NOT NULL,
  "last_post_id" bigint DEFAULT '0' NOT NULL,
  PRIMARY KEY ("forum_id"),
  Constraint "forum_code" UNIQUE ("forum_code")
);
CREATE INDEX "forum_id" on "forum" ("forum_id");


--
-- Table: forum_settings
--
CREATE TABLE "forum_settings" (
  "forum_id" bigint DEFAULT '0' NOT NULL,
  "type" character varying(48) NOT NULL,
  "value" character varying(255) NOT NULL,
  PRIMARY KEY ("forum_id", "type")
);
CREATE INDEX "forum_id2" on "forum_settings" ("forum_id");


--
-- Table: hit
--
CREATE TABLE "hit" (
  "hit_id" serial NOT NULL,
  "object_type" character varying(12) NOT NULL,
  "object_id" bigint DEFAULT '0' NOT NULL,
  "hit_new" bigint DEFAULT '0' NOT NULL,
  "hit_today" bigint DEFAULT '0' NOT NULL,
  "hit_yesterday" bigint DEFAULT '0' NOT NULL,
  "hit_weekly" bigint DEFAULT '0' NOT NULL,
  "hit_monthly" bigint DEFAULT '0' NOT NULL,
  "hit_all" bigint DEFAULT '0' NOT NULL,
  "last_update_time" bigint DEFAULT '0' NOT NULL,
  PRIMARY KEY ("hit_id")
);
CREATE INDEX "object" on "hit" ("object_type", "object_id");
CREATE INDEX "object_type" on "hit" ("object_type");
CREATE INDEX "last_update_time" on "hit" ("last_update_time");


--
-- Table: log_action
--
CREATE TABLE "log_action" (
  "user_id" bigint DEFAULT '0' NOT NULL,
  "action" character varying(24) DEFAULT NULL,
  "object_type" character varying(12) DEFAULT NULL,
  "object_id" bigint DEFAULT NULL,
  "text" text,
  "forum_id" bigint DEFAULT '0' NOT NULL,
  "time" bigint DEFAULT '0' NOT NULL
);
CREATE INDEX "user_id" on "log_action" ("user_id");
CREATE INDEX "forum_id3" on "log_action" ("forum_id");


--
-- Table: log_error
--
CREATE TABLE "log_error" (
  "error_id" serial NOT NULL,
  "text" text NOT NULL,
  "time" bigint DEFAULT '0' NOT NULL,
  "level" smallint DEFAULT '1' NOT NULL,
  PRIMARY KEY ("error_id")
);



--
-- Table: log_path
--
CREATE TABLE "log_path" (
  "path_id" serial NOT NULL,
  "session_id" character varying(72) DEFAULT NULL,
  "user_id" bigint DEFAULT '0' NOT NULL,
  "path" character varying(255) DEFAULT '' NOT NULL,
  "get" character varying(255) DEFAULT NULL,
  "post" text,
  "loadtime" numeric(8,2) DEFAULT '0' NOT NULL,
  "time" bigint DEFAULT '0' NOT NULL,
  PRIMARY KEY ("path_id")
);
CREATE INDEX "path" on "log_path" ("path");
CREATE INDEX "session_id" on "log_path" ("session_id");
CREATE INDEX "user_id2" on "log_path" ("user_id");


--
-- Table: message
--
CREATE TABLE "message" (
  "message_id" serial NOT NULL,
  "from_id" bigint DEFAULT '0' NOT NULL,
  "to_id" bigint DEFAULT '0' NOT NULL,
  "title" character varying(255) NOT NULL,
  "text" text NOT NULL,
  "post_ip" character varying(32) DEFAULT '' NOT NULL,
  "from_status" character varying(7) DEFAULT 'open' NOT NULL,
  "to_status" character varying(7) DEFAULT 'open' NOT NULL,
  "post_on" bigint DEFAULT '0' NOT NULL,
  PRIMARY KEY ("message_id")
);
CREATE INDEX "message_id" on "message" ("message_id");
CREATE INDEX "to_id" on "message" ("to_id");
CREATE INDEX "from_id" on "message" ("from_id");


--
-- Table: message_unread
--
CREATE TABLE "message_unread" (
  "message_id" bigint DEFAULT '0' NOT NULL,
  "user_id" bigint DEFAULT '0' NOT NULL,
  PRIMARY KEY ("message_id", "user_id")
);
CREATE INDEX "message_id2" on "message_unread" ("message_id");


--
-- Table: poll
--
CREATE TABLE "poll" (
  "poll_id" serial NOT NULL,
  "forum_id" bigint DEFAULT '0' NOT NULL,
  "author_id" bigint DEFAULT '0' NOT NULL,
  "multi" character varying(1) DEFAULT '0' NOT NULL,
  "anonymous" character varying(1) DEFAULT '0' NOT NULL,
  "time" integer DEFAULT NULL,
  "duration" integer DEFAULT NULL,
  "vote_no" integer DEFAULT '0' NOT NULL,
  "title" character varying(128) DEFAULT NULL,
  "hit" bigint DEFAULT '0' NOT NULL,
  PRIMARY KEY ("poll_id")
);
CREATE INDEX "poll_id" on "poll" ("poll_id");
CREATE INDEX "author_id2" on "poll" ("author_id");


--
-- Table: poll_option
--
CREATE TABLE "poll_option" (
  "option_id" serial NOT NULL,
  "poll_id" bigint DEFAULT '0' NOT NULL,
  "text" character varying(255) DEFAULT NULL,
  "vote_no" integer DEFAULT '0' NOT NULL,
  PRIMARY KEY ("option_id")
);
CREATE INDEX "option_id" on "poll_option" ("option_id");
CREATE INDEX "poll_id2" on "poll_option" ("poll_id");


--
-- Table: poll_result
--
CREATE TABLE "poll_result" (
  "option_id" bigint DEFAULT '0' NOT NULL,
  "poll_id" bigint DEFAULT '0' NOT NULL,
  "poster_id" bigint DEFAULT '0' NOT NULL,
  "poster_ip" character varying(32) DEFAULT NULL
);
CREATE INDEX "poll_id3" on "poll_result" ("poll_id");
CREATE INDEX "option_id2" on "poll_result" ("option_id");


--
-- Table: scheduled_email
--
CREATE TABLE "scheduled_email" (
  "email_id" serial NOT NULL,
  "email_type" character varying(24) DEFAULT NULL,
  "processed" character varying(1) DEFAULT 'N' NOT NULL,
  "from_email" character varying(128) DEFAULT NULL,
  "to_email" character varying(128) DEFAULT NULL,
  "subject" text,
  "plain_body" text,
  "html_body" text,
  "time" bigint DEFAULT '0' NOT NULL,
  PRIMARY KEY ("email_id")
);
CREATE INDEX "processed" on "scheduled_email" ("processed");


--
-- Table: security_code
--
CREATE TABLE "security_code" (
  "security_code_id" serial NOT NULL,
  "user_id" bigint DEFAULT '0' NOT NULL,
  "type" smallint DEFAULT '0' NOT NULL,
  "code" character varying(12) NOT NULL,
  "time" bigint DEFAULT '0' NOT NULL,
  "note" character varying(255),
  PRIMARY KEY ("security_code_id")
);



--
-- Table: session
--
CREATE TABLE "session" (
  "id" character(72) DEFAULT '' NOT NULL,
  "session_data" text,
  "expires" bigint DEFAULT '0',
  PRIMARY KEY ("id")
);



--
-- Table: share
--
CREATE TABLE "share" (
  "user_id" bigint DEFAULT '0' NOT NULL,
  "object_type" character varying(12) DEFAULT '' NOT NULL,
  "object_id" bigint DEFAULT '0' NOT NULL,
  "time" integer DEFAULT '0' NOT NULL,
  PRIMARY KEY ("user_id", "object_id", "object_type")
);
CREATE INDEX "user_id3" on "share" ("user_id");


--
-- Table: star
--
CREATE TABLE "star" (
  "user_id" bigint DEFAULT '0' NOT NULL,
  "object_type" character varying(12) DEFAULT '' NOT NULL,
  "object_id" bigint DEFAULT '0' NOT NULL,
  "time" integer DEFAULT '0' NOT NULL,
  PRIMARY KEY ("user_id", "object_id", "object_type")
);
CREATE INDEX "user_id4" on "star" ("user_id");


--
-- Table: stat
--
CREATE TABLE "stat" (
  "stat_id" serial NOT NULL,
  "stat_key" character varying(255) NOT NULL,
  "stat_value" bigint DEFAULT '0' NOT NULL,
  "date" bigint DEFAULT '0' NOT NULL,
  PRIMARY KEY ("stat_id")
);
CREATE INDEX "key" on "stat" ("stat_key");


--
-- Table: topic
--
CREATE TABLE "topic" (
  "topic_id" serial NOT NULL,
  "forum_id" bigint DEFAULT '0' NOT NULL,
  "title" character varying(255) DEFAULT NULL,
  "post_on" bigint DEFAULT '0' NOT NULL,
  "closed" character varying(1) DEFAULT '0' NOT NULL,
  "sticky" character varying(1) DEFAULT '0' NOT NULL,
  "elite" character varying(1) DEFAULT '0' NOT NULL,
  "hit" bigint DEFAULT '0' NOT NULL,
  "last_updator_id" bigint DEFAULT '0' NOT NULL,
  "author_id" bigint DEFAULT '0' NOT NULL,
  "total_replies" bigint DEFAULT '0' NOT NULL,
  "status" character varying(7) DEFAULT 'healthy' NOT NULL,
  "last_update_date" bigint DEFAULT '0' NOT NULL,
  PRIMARY KEY ("topic_id")
);
CREATE INDEX "author_id3" on "topic" ("author_id");
CREATE INDEX "forum_id4" on "topic" ("forum_id");


--
-- Table: upload
--
CREATE TABLE "upload" (
  "upload_id" serial NOT NULL,
  "user_id" bigint DEFAULT '0' NOT NULL,
  "forum_id" bigint DEFAULT '0' NOT NULL,
  "filename" character varying(36) DEFAULT NULL,
  "filesize" numeric(8,2) DEFAULT NULL,
  "filetype" character varying(4) DEFAULT NULL,
  PRIMARY KEY ("upload_id")
);
CREATE INDEX "upload_id2" on "upload" ("upload_id");


--
-- Table: user
--
CREATE TABLE "user" (
  "user_id" serial NOT NULL,
  "username" character varying(32) NOT NULL,
  "password" character varying(32) DEFAULT '000000' NOT NULL,
  "nickname" character varying(100) NOT NULL,
  "gender" character varying(2) DEFAULT 'NA' NOT NULL,
  "email" character varying(255) NOT NULL,
  "point" integer DEFAULT '0' NOT NULL,
  "register_time" bigint DEFAULT '0' NOT NULL,
  "register_ip" character varying(32) NOT NULL,
  "last_login_ip" character varying(32) DEFAULT NULL,
  "login_times" integer DEFAULT '1' NOT NULL,
  "status" character varying(10) DEFAULT 'unverified' NOT NULL,
  "threads" bigint DEFAULT '0' NOT NULL,
  "replies" bigint DEFAULT '0' NOT NULL,
  "lang" character(2) DEFAULT 'cn',
  "country" character(2) DEFAULT 'cn',
  "state_id" bigint DEFAULT '0' NOT NULL,
  "city_id" bigint DEFAULT '0' NOT NULL,
  "last_login_on" bigint DEFAULT '0' NOT NULL,
  PRIMARY KEY ("user_id"),
  Constraint "username" UNIQUE ("username")
);
CREATE INDEX "register_time" on "user" ("register_time");
CREATE INDEX "point" on "user" ("point");


--
-- Table: user_activation
--
CREATE TABLE "user_activation" (
  "user_id" bigint DEFAULT '0' NOT NULL,
  "activation_code" character varying(12) DEFAULT NULL,
  "new_email" character varying(255) DEFAULT NULL,
  PRIMARY KEY ("user_id")
);
CREATE INDEX "user_id5" on "user_activation" ("user_id");


--
-- Table: user_details
--
CREATE TABLE "user_details" (
  "user_id" bigint DEFAULT '0' NOT NULL,
  "qq" character varying(14) DEFAULT NULL,
  "msn" character varying(64) DEFAULT NULL,
  "yahoo" character varying(64) DEFAULT NULL,
  "skype" character varying(64) DEFAULT NULL,
  "gtalk" character varying(64) DEFAULT NULL,
  "homepage" character varying(255) DEFAULT NULL,
  "birthday" date DEFAULT NULL,
  PRIMARY KEY ("user_id")
);
CREATE INDEX "user_id6" on "user_details" ("user_id");


--
-- Table: user_forum
--
CREATE TABLE "user_forum" (
  "user_id" bigint DEFAULT '0' NOT NULL,
  "forum_id" bigint DEFAULT '0' NOT NULL,
  "status" character varying(9) DEFAULT 'user' NOT NULL,
  "time" bigint DEFAULT '0' NOT NULL,
  PRIMARY KEY ("user_id", "forum_id")
);



--
-- Table: user_online
--
CREATE TABLE "user_online" (
  "sessionid" character varying(72) DEFAULT '0' NOT NULL,
  "user_id" bigint DEFAULT '0' NOT NULL,
  "path" character varying(255) NOT NULL,
  "title" character varying(255) NOT NULL,
  "start_time" bigint DEFAULT '0' NOT NULL,
  "last_time" bigint DEFAULT '0' NOT NULL,
  PRIMARY KEY ("sessionid")
);
CREATE INDEX "start_time" on "user_online" ("start_time");
CREATE INDEX "last_time" on "user_online" ("last_time");


--
-- Table: user_profile_photo
--
CREATE TABLE "user_profile_photo" (
  "user_id" bigint DEFAULT '0' NOT NULL,
  "type" character varying(6) DEFAULT 'upload' NOT NULL,
  "value" character varying(255) DEFAULT '0' NOT NULL,
  "width" smallint DEFAULT '0' NOT NULL,
  "height" smallint DEFAULT '0' NOT NULL,
  "time" bigint DEFAULT '0' NOT NULL,
  PRIMARY KEY ("user_id")
);



--
-- Table: user_role
--
CREATE TABLE "user_role" (
  "user_id" bigint DEFAULT '0' NOT NULL,
  "role" character varying(9) DEFAULT 'user',
  "field" character varying(32) DEFAULT '' NOT NULL
);
CREATE INDEX "user_id7" on "user_role" ("user_id");
CREATE INDEX "field" on "user_role" ("field");


--
-- Table: user_settings
--
CREATE TABLE "user_settings" (
  "user_id" bigint DEFAULT '0' NOT NULL,
  "type" character varying(48) NOT NULL,
  "value" character varying(48) NOT NULL,
  PRIMARY KEY ("user_id", "type")
);
CREATE INDEX "user_id8" on "user_settings" ("user_id");


--
-- Table: variables
--
CREATE TABLE "variables" (
  "type" character varying(6) DEFAULT 'global' NOT NULL,
  "name" character varying(32) DEFAULT '' NOT NULL,
  "value" character varying(255) DEFAULT '' NOT NULL,
  PRIMARY KEY ("type", "name")
);
CREATE INDEX "type" on "variables" ("type");


--
-- Table: visit
--
CREATE TABLE "visit" (
  "user_id" bigint DEFAULT '0' NOT NULL,
  "object_type" character varying(12) DEFAULT '' NOT NULL,
  "object_id" bigint DEFAULT '0' NOT NULL,
  "time" integer DEFAULT '0' NOT NULL,
  PRIMARY KEY ("user_id", "object_type", "object_id")
);
CREATE INDEX "user_id9" on "visit" ("user_id");
