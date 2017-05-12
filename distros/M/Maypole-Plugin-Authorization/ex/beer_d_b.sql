USE beer_d_b;

DROP TABLE IF EXISTS role_assignments;

DROP TABLE IF EXISTS permissions;

DROP TABLE IF EXISTS users;

DROP TABLE IF EXISTS auth_roles;

--
-- Table structure for table `auth_roles`
--
CREATE TABLE auth_roles (
  id int(11) NOT NULL auto_increment,
  name varchar(40) NOT NULL default '',
  PRIMARY KEY  (id)
) TYPE=InnoDB;
--
-- Dumping data for table `auth_roles`
--
INSERT INTO auth_roles VALUES (1,'default');
INSERT INTO auth_roles VALUES (2,'admin');
INSERT INTO auth_roles VALUES (3,'user-admin');
INSERT INTO auth_roles VALUES (4,'enthusiast');
--
-- Table structure for table `permissions`
--

CREATE TABLE permissions (
  id int(11) NOT NULL auto_increment,
  auth_role_id int(11) NOT NULL default '0',
  model_class varchar(100) NOT NULL default '',
  method varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),
  UNIQUE KEY auth_role_id (auth_role_id,model_class,method),
  KEY model_class (model_class(20)),
  KEY method (method(20)),
  CONSTRAINT `permissions_ibfk_1` FOREIGN KEY (`auth_role_id`) REFERENCES `auth_roles` (`id`)
) TYPE=InnoDB;
--
-- Dumping data for table `permissions`
--
INSERT INTO permissions VALUES (1,3,'BeerDB::Users','*');
INSERT INTO permissions VALUES (2,2,'BeerDB::AuthRoles','*');
INSERT INTO permissions VALUES (3,2,'BeerDB::Permissions','*');
INSERT INTO permissions VALUES (4,2,'BeerDB::RoleAssignments','*');
INSERT INTO permissions VALUES (5,4,'BeerDB::Beer','*');
INSERT INTO permissions VALUES (6,1,'BeerDB::Beer','view');
INSERT INTO permissions VALUES (7,1,'BeerDB::Beer','list');
INSERT INTO permissions VALUES (8,1,'BeerDB::Brewery','list');
INSERT INTO permissions VALUES (9,1,'BeerDB::Brewery','view');
INSERT INTO permissions VALUES (10,4,'BeerDB::Brewery','*');
INSERT INTO permissions VALUES (11,1,'BeerDB::Pub','list');
INSERT INTO permissions VALUES (12,1,'BeerDB::Pub','view');
INSERT INTO permissions VALUES (13,4,'BeerDB::Pub','*');
INSERT INTO permissions VALUES (14,1,'BeerDB::Style','list');
INSERT INTO permissions VALUES (15,1,'BeerDB::Style','view');
INSERT INTO permissions VALUES (16,4,'BeerDB::Style','*');
INSERT INTO permissions VALUES (17,1,'BeerDB::Handpump','list');
INSERT INTO permissions VALUES (18,1,'BeerDB::Handpump','view');
INSERT INTO permissions VALUES (19,4,'BeerDB::Handpump','*');

--
-- Table structure for table `users`
--
CREATE TABLE users (
  id int(11) NOT NULL auto_increment,
  name varchar(100) NOT NULL default '',
  UID varchar(20) NOT NULL default '',
  password varchar(20) NOT NULL default '',
  PRIMARY KEY  (id),
  UNIQUE KEY UID (UID)
) TYPE=InnoDB;
--
-- Dumping data for table `users`
--
INSERT INTO users VALUES (1,'An Administrator','admin','admin');
INSERT INTO users VALUES (2,'A Guest','guest','guest');
INSERT INTO users VALUES (3,'A Beer Lover','beer','beer');

--
-- Table structure for table `role_assignments`
--
CREATE TABLE role_assignments (
  id int(11) NOT NULL auto_increment,
  user_id int(11) NOT NULL default '0',
  auth_role_id int(11) NOT NULL default '0',
  PRIMARY KEY  (id),
  UNIQUE KEY user_id (user_id,auth_role_id),
  KEY auth_role_id (auth_role_id),
  CONSTRAINT `role_assignments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `role_assignments_ibfk_2` FOREIGN KEY (`auth_role_id`) REFERENCES `auth_roles` (`id`)
) TYPE=InnoDB;
--
-- Dumping data for table `role_assignments`
--
INSERT INTO role_assignments VALUES (1,1,1);
INSERT INTO role_assignments VALUES (2,1,2);
INSERT INTO role_assignments VALUES (3,1,3);
INSERT INTO role_assignments VALUES (4,2,1);

