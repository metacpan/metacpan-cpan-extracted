-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Sun Oct 12 14:37:35 2008
-- 
BEGIN TRANSACTION;


--
-- Table: banned_ip
--
CREATE TABLE banned_ip (
  ip_id INTEGER PRIMARY KEY NOT NULL,
  cidr_ip varchar(20) NOT NULL DEFAULT '',
  time int(11) NOT NULL DEFAULT '0'
);


--
-- Table: comment
--
CREATE TABLE comment (
  comment_id INTEGER PRIMARY KEY NOT NULL,
  reply_to int(11) NOT NULL DEFAULT '0',
  text text NOT NULL,
  post_ip varchar(32) NOT NULL DEFAULT '',
  formatter varchar(16) NOT NULL DEFAULT 'ubb',
  object_type varchar(30) NOT NULL,
  object_id int(11) NOT NULL DEFAULT '0',
  author_id int(11) NOT NULL DEFAULT '0',
  title varchar(255) NOT NULL DEFAULT '',
  forum_id int(11) NOT NULL DEFAULT '0',
  upload_id int(11) NOT NULL DEFAULT '0',
  post_on int(11) NOT NULL DEFAULT '0',
  update_on int(11) NOT NULL DEFAULT '0'
);

CREATE INDEX comment_id_comment ON comment (comment_id);
CREATE INDEX upload_id_comment ON comment (upload_id);
CREATE INDEX author_id_comment ON comment (author_id);

--
-- Table: filter_word
--
CREATE TABLE filter_word (
  word varchar(64) NOT NULL,
  type enum(19) NOT NULL DEFAULT 'username_reserved',
  PRIMARY KEY (word, type)
);

CREATE INDEX word_filter_word ON filter_word (word);

--
-- Table: forum
--
CREATE TABLE forum (
  forum_id INTEGER PRIMARY KEY NOT NULL,
  forum_code varchar(25) NOT NULL,
  name varchar(100) NOT NULL,
  description varchar(255) NOT NULL,
  forum_type varchar(16) NOT NULL,
  policy enum(9) NOT NULL DEFAULT 'public',
  total_members int(8) NOT NULL DEFAULT '0',
  total_topics int(11) NOT NULL DEFAULT '0',
  total_replies int(11) NOT NULL DEFAULT '0',
  status enum(7) NOT NULL DEFAULT 'healthy',
  last_post_id int(11) NOT NULL DEFAULT '0'
);

CREATE INDEX forum_id_forum ON forum (forum_id);
CREATE UNIQUE INDEX forum_code_forum ON forum (forum_code);

--
-- Table: forum_settings
--
CREATE TABLE forum_settings (
  forum_id int(11) NOT NULL DEFAULT '0',
  type varchar(48) NOT NULL,
  value varchar(255) NOT NULL,
  PRIMARY KEY (forum_id, type)
);

CREATE INDEX forum_id_forum_settings ON forum_settings (forum_id);

--
-- Table: hit
--
CREATE TABLE hit (
  hit_id INTEGER PRIMARY KEY NOT NULL,
  object_type varchar(12) NOT NULL,
  object_id int(11) NOT NULL DEFAULT '0',
  hit_new int(11) NOT NULL DEFAULT '0',
  hit_today int(11) NOT NULL DEFAULT '0',
  hit_yesterday int(11) NOT NULL DEFAULT '0',
  hit_weekly int(11) NOT NULL DEFAULT '0',
  hit_monthly int(11) NOT NULL DEFAULT '0',
  hit_all int(11) NOT NULL DEFAULT '0',
  last_update_time int(11) NOT NULL DEFAULT '0'
);

CREATE INDEX object_hit ON hit (object_type, object_id);
CREATE INDEX object_type_hit ON hit (object_type);
CREATE INDEX last_update_time_hit ON hit (last_update_time);

--
-- Table: log_action
--
CREATE TABLE log_action (
  user_id int(11) NOT NULL DEFAULT '0',
  action varchar(24) DEFAULT NULL,
  object_type varchar(12) DEFAULT NULL,
  object_id int(11) DEFAULT NULL,
  text text,
  forum_id int(11) NOT NULL DEFAULT '0',
  time int(11) NOT NULL DEFAULT '0'
);

CREATE INDEX user_id_log_action ON log_action (user_id);
CREATE INDEX forum_id_log_action ON log_action (forum_id);

--
-- Table: log_error
--
CREATE TABLE log_error (
  error_id INTEGER PRIMARY KEY NOT NULL,
  text text NOT NULL,
  time int(11) NOT NULL DEFAULT '0',
  level smallint(1) NOT NULL DEFAULT '1'
);


--
-- Table: log_path
--
CREATE TABLE log_path (
  path_id INTEGER PRIMARY KEY NOT NULL,
  session_id varchar(72) DEFAULT NULL,
  user_id int(11) NOT NULL DEFAULT '0',
  path varchar(255) NOT NULL DEFAULT '',
  get varchar(255) DEFAULT NULL,
  post text,
  loadtime double(8,2) NOT NULL DEFAULT '0',
  time int(11) NOT NULL DEFAULT '0'
);

CREATE INDEX path_log_path ON log_path (path);
CREATE INDEX session_id_log_path ON log_path (session_id);
CREATE INDEX user_id_log_path ON log_path (user_id);

--
-- Table: message
--
CREATE TABLE message (
  message_id INTEGER PRIMARY KEY NOT NULL,
  from_id int(11) NOT NULL DEFAULT '0',
  to_id int(11) NOT NULL DEFAULT '0',
  title varchar(255) NOT NULL,
  text text NOT NULL,
  post_ip varchar(32) NOT NULL DEFAULT '',
  from_status enum(7) NOT NULL DEFAULT 'open',
  to_status enum(7) NOT NULL DEFAULT 'open',
  post_on int(11) NOT NULL DEFAULT '0'
);

CREATE INDEX message_id_message ON message (message_id);
CREATE INDEX to_id_message ON message (to_id);
CREATE INDEX from_id_message ON message (from_id);

--
-- Table: message_unread
--
CREATE TABLE message_unread (
  message_id int(11) NOT NULL DEFAULT '0',
  user_id int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (message_id, user_id)
);

CREATE INDEX message_id_message_unread ON message_unread (message_id);

--
-- Table: poll
--
CREATE TABLE poll (
  poll_id INTEGER PRIMARY KEY NOT NULL,
  forum_id int(11) NOT NULL DEFAULT '0',
  author_id int(11) NOT NULL DEFAULT '0',
  multi enum(1) NOT NULL DEFAULT '0',
  anonymous enum(1) NOT NULL DEFAULT '0',
  time int(10) DEFAULT NULL,
  duration int(10) DEFAULT NULL,
  vote_no mediumint(8) NOT NULL DEFAULT '0',
  title varchar(128) DEFAULT NULL,
  hit int(11) NOT NULL DEFAULT '0'
);

CREATE INDEX poll_id_poll ON poll (poll_id);
CREATE INDEX author_id_poll ON poll (author_id);

--
-- Table: poll_option
--
CREATE TABLE poll_option (
  option_id INTEGER PRIMARY KEY NOT NULL,
  poll_id int(11) NOT NULL DEFAULT '0',
  text varchar(255) DEFAULT NULL,
  vote_no mediumint(8) NOT NULL DEFAULT '0'
);

CREATE INDEX option_id_poll_option ON poll_option (option_id);
CREATE INDEX poll_id_poll_option ON poll_option (poll_id);

--
-- Table: poll_result
--
CREATE TABLE poll_result (
  option_id int(11) NOT NULL DEFAULT '0',
  poll_id int(11) NOT NULL DEFAULT '0',
  poster_id int(11) NOT NULL DEFAULT '0',
  poster_ip varchar(32) DEFAULT NULL
);

CREATE INDEX poll_id_poll_result ON poll_result (poll_id);
CREATE INDEX option_id_poll_result ON poll_result (option_id);

--
-- Table: scheduled_email
--
CREATE TABLE scheduled_email (
  email_id INTEGER PRIMARY KEY NOT NULL,
  email_type varchar(24) DEFAULT NULL,
  processed enum(1) NOT NULL DEFAULT 'N',
  from_email varchar(128) DEFAULT NULL,
  to_email varchar(128) DEFAULT NULL,
  subject text,
  plain_body text,
  html_body text,
  time int(11) NOT NULL DEFAULT '0'
);

CREATE INDEX processed_scheduled_email ON scheduled_email (processed);

--
-- Table: security_code
--
CREATE TABLE security_code (
  security_code_id INTEGER PRIMARY KEY NOT NULL,
  user_id int(11) NOT NULL DEFAULT '0',
  type tinyint(1) NOT NULL DEFAULT '0',
  code varchar(12) NOT NULL,
  time int(11) NOT NULL DEFAULT '0',
  note VARCHAR(255)
);


--
-- Table: session
--
CREATE TABLE session (
  id char(72) NOT NULL DEFAULT '',
  session_data text,
  expires int(11) DEFAULT '0',
  PRIMARY KEY (id)
);


--
-- Table: share
--
CREATE TABLE share (
  user_id int(11) NOT NULL DEFAULT '0',
  object_type varchar(12) NOT NULL DEFAULT '',
  object_id int(11) NOT NULL DEFAULT '0',
  time int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (user_id, object_id, object_type)
);

CREATE INDEX user_id_share ON share (user_id);

--
-- Table: star
--
CREATE TABLE star (
  user_id int(11) NOT NULL DEFAULT '0',
  object_type varchar(12) NOT NULL DEFAULT '',
  object_id int(11) NOT NULL DEFAULT '0',
  time int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (user_id, object_id, object_type)
);

CREATE INDEX user_id_star ON star (user_id);

--
-- Table: stat
--
CREATE TABLE stat (
  stat_id INTEGER PRIMARY KEY NOT NULL,
  stat_key varchar(255) NOT NULL,
  stat_value bigint(21) NOT NULL DEFAULT '0',
  date int(11) NOT NULL DEFAULT '0'
);

CREATE INDEX key_stat ON stat (stat_key);

--
-- Table: topic
--
CREATE TABLE topic (
  topic_id INTEGER PRIMARY KEY NOT NULL,
  forum_id int(11) NOT NULL DEFAULT '0',
  title varchar(255) DEFAULT NULL,
  post_on int(11) NOT NULL DEFAULT '0',
  closed enum(1) NOT NULL DEFAULT '0',
  sticky enum(1) NOT NULL DEFAULT '0',
  elite enum(1) NOT NULL DEFAULT '0',
  hit int(11) NOT NULL DEFAULT '0',
  last_updator_id int(11) NOT NULL DEFAULT '0',
  author_id int(11) NOT NULL DEFAULT '0',
  total_replies int(11) NOT NULL DEFAULT '0',
  status enum(7) NOT NULL DEFAULT 'healthy',
  last_update_date int(11) NOT NULL DEFAULT '0'
);

CREATE INDEX author_id_topic ON topic (author_id);
CREATE INDEX forum_id_topic ON topic (forum_id);

--
-- Table: upload
--
CREATE TABLE upload (
  upload_id INTEGER PRIMARY KEY NOT NULL,
  user_id int(11) NOT NULL DEFAULT '0',
  forum_id int(11) NOT NULL DEFAULT '0',
  filename varchar(36) DEFAULT NULL,
  filesize double(8,2) DEFAULT NULL,
  filetype varchar(4) DEFAULT NULL
);

CREATE INDEX upload_id_upload ON upload (upload_id);

--
-- Table: user
--
CREATE TABLE user (
  user_id INTEGER PRIMARY KEY NOT NULL,
  username varchar(32) NOT NULL,
  password varchar(32) NOT NULL DEFAULT '000000',
  nickname varchar(100) NOT NULL,
  gender enum(2) NOT NULL DEFAULT 'NA',
  email varchar(255) NOT NULL,
  point int(8) NOT NULL DEFAULT '0',
  register_time int(11) NOT NULL DEFAULT '0',
  register_ip varchar(32) NOT NULL,
  last_login_ip varchar(32) DEFAULT NULL,
  login_times mediumint(8) NOT NULL DEFAULT '1',
  status enum(10) NOT NULL DEFAULT 'unverified',
  threads int(11) NOT NULL DEFAULT '0',
  replies int(11) NOT NULL DEFAULT '0',
  lang char(2) DEFAULT 'cn',
  country char(2) DEFAULT 'cn',
  state_id int(11) NOT NULL DEFAULT '0',
  city_id int(11) NOT NULL DEFAULT '0',
  last_login_on int(11) NOT NULL DEFAULT '0'
);

CREATE INDEX register_time_user ON user (register_time);
CREATE INDEX point_user ON user (point);
CREATE UNIQUE INDEX username_user ON user (username);

--
-- Table: user_activation
--
CREATE TABLE user_activation (
  user_id INTEGER PRIMARY KEY NOT NULL DEFAULT '0',
  activation_code varchar(12) DEFAULT NULL,
  new_email varchar(255) DEFAULT NULL
);

CREATE INDEX user_id_user_activation ON user_activation (user_id);

--
-- Table: user_details
--
CREATE TABLE user_details (
  user_id INTEGER PRIMARY KEY NOT NULL DEFAULT '0',
  qq varchar(14) DEFAULT NULL,
  msn varchar(64) DEFAULT NULL,
  yahoo varchar(64) DEFAULT NULL,
  skype varchar(64) DEFAULT NULL,
  gtalk varchar(64) DEFAULT NULL,
  homepage varchar(255) DEFAULT NULL,
  birthday date DEFAULT NULL
);

CREATE INDEX user_id_user_details ON user_details (user_id);

--
-- Table: user_forum
--
CREATE TABLE user_forum (
  user_id int(11) NOT NULL DEFAULT '0',
  forum_id int(11) NOT NULL DEFAULT '0',
  status enum(9) NOT NULL DEFAULT 'user',
  time int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (user_id, forum_id)
);


--
-- Table: user_online
--
CREATE TABLE user_online (
  sessionid varchar(72) NOT NULL DEFAULT '0',
  user_id int(11) NOT NULL DEFAULT '0',
  path varchar(255) NOT NULL,
  title varchar(255) NOT NULL,
  start_time int(11) NOT NULL DEFAULT '0',
  last_time int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (sessionid)
);

CREATE INDEX start_time_user_online ON user_online (start_time);
CREATE INDEX last_time_user_online ON user_online (last_time);

--
-- Table: user_profile_photo
--
CREATE TABLE user_profile_photo (
  user_id INTEGER PRIMARY KEY NOT NULL DEFAULT '0',
  type enum(6) NOT NULL DEFAULT 'upload',
  value varchar(255) NOT NULL DEFAULT '0',
  width smallint(6) NOT NULL DEFAULT '0',
  height smallint(6) NOT NULL DEFAULT '0',
  time int(11) NOT NULL DEFAULT '0'
);


--
-- Table: user_role
--
CREATE TABLE user_role (
  user_id int(11) NOT NULL DEFAULT '0',
  role enum(9) DEFAULT 'user',
  field varchar(32) NOT NULL DEFAULT ''
);

CREATE INDEX user_id_user_role ON user_role (user_id);
CREATE INDEX field_user_role ON user_role (field);

--
-- Table: user_settings
--
CREATE TABLE user_settings (
  user_id int(11) NOT NULL DEFAULT '0',
  type varchar(48) NOT NULL,
  value varchar(48) NOT NULL,
  PRIMARY KEY (user_id, type)
);

CREATE INDEX user_id_user_settings ON user_settings (user_id);

--
-- Table: variables
--
CREATE TABLE variables (
  type enum(6) NOT NULL DEFAULT 'global',
  name varchar(32) NOT NULL DEFAULT '',
  value varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (type, name)
);

CREATE INDEX type_variables ON variables (type);

--
-- Table: visit
--
CREATE TABLE visit (
  user_id int(11) NOT NULL DEFAULT '0',
  object_type varchar(12) NOT NULL DEFAULT '',
  object_id int(11) NOT NULL DEFAULT '0',
  time int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (user_id, object_type, object_id)
);

CREATE INDEX user_id_visit ON visit (user_id);

COMMIT;
