DROP TABLE IF EXISTS `requests`;
CREATE TABLE `requests` (
  `requestid`   int(10)         unsigned NOT NULL AUTO_INCREMENT,
  `section`     varchar(15)     COLLATE utf8_unicode_ci NOT NULL,
  `command`     varchar(15)     COLLATE utf8_unicode_ci NOT NULL,
  `actions`     varchar(1000)   COLLATE utf8_unicode_ci DEFAULT NULL,
  `layout`      varchar(255)    COLLATE utf8_unicode_ci DEFAULT NULL,
  `content`     varchar(255)    COLLATE utf8_unicode_ci DEFAULT NULL,
  `onsuccess`   varchar(32)     COLLATE utf8_unicode_ci DEFAULT NULL,
  `onerror`     varchar(32)     COLLATE utf8_unicode_ci DEFAULT NULL,
  `onfailure`   varchar(32)     COLLATE utf8_unicode_ci DEFAULT NULL,
  `secure`      enum('off','on','either','both') DEFAULT 'off',
  `rewrite`     varchar(255)    COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`requestid`),
  KEY `IXSECT` (`section`,`command`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- core requests
INSERT INTO `requests` VALUES (1,'realm','admin','Content::GetVersion,Menus::LoadMenus','admin/layout.html','','','','','off','');
INSERT INTO `requests` VALUES (2,'realm','popup','','public/popup.html','','','','','off','');
INSERT INTO `requests` VALUES (3,'realm','public','Content::GetVersion,Hits::SetHits,Menus::LoadMenus','public/layout.html','','','','','off','');
INSERT INTO `requests` VALUES (4,'realm','wide','','public/layout-wide.html','','','','','off','');
INSERT INTO `requests` VALUES (5,'error','badmail','','','public/badmail.html','','','','off','');
INSERT INTO `requests` VALUES (6,'error','badcmd','','','public/badcommand.html','','','','off','');
INSERT INTO `requests` VALUES (7,'error','banuser','','','public/banuser.html','','','','off','');
INSERT INTO `requests` VALUES (8,'error','badaccess','Users::LoggedIn','','public/badaccess.html','','error-login','','off','');
INSERT INTO `requests` VALUES (9,'error','baduser','','','public/baduser.html','','','','off','');
INSERT INTO `requests` VALUES (10,'error','login','Users::Store','','users/user-login.html','','','','off','');
INSERT INTO `requests` VALUES (11,'error','message','','','public/error_message.html','','','','off','');
INSERT INTO `requests` VALUES (12,'home','admin','','','admin/backend_index.html','','','','off','');
INSERT INTO `requests` VALUES (13,'home','prefs','CPAN::Authors::Basic','','cpan/prefs.html','','','','off','');
INSERT INTO `requests` VALUES (14,'home','status','CPAN::Authors::Status','','content/status.html','','','','off','');
INSERT INTO `requests` VALUES (15,'home','main','CPAN::Authors::Status','','content/welcome.html','','','','off','');
INSERT INTO `requests` VALUES (16,'req','admin','Requests::Admin',NULL,'request/request_adminlist.html','','',NULL,'off',NULL);
INSERT INTO `requests` VALUES (17,'req','add','Requests::Add',NULL,'request/request_adminedit.html','','',NULL,'off',NULL);
INSERT INTO `requests` VALUES (18,'req','edit','Requests::Edit',NULL,'request/request_adminedit.html','','',NULL,'off',NULL);
INSERT INTO `requests` VALUES (19,'req','save','Requests::Save',NULL,'','req-edit','req-edit',NULL,'off',NULL);
INSERT INTO `requests` VALUES (20,'req','delete','Requests::Delete',NULL,'','req-admin','',NULL,'off',NULL);

-- admin plugin requests
INSERT INTO `requests` VALUES (21,'menu','save','Menus::Save','','','menu-edit','menu-edit','','off','');
INSERT INTO `requests` VALUES (22,'menu','admin','Menus::Admin','','menus/menu_adminlist.html','','','','off','');
INSERT INTO `requests` VALUES (23,'menu','add','Menus::Add','','menus/menu_adminedit.html','','','','off','');
INSERT INTO `requests` VALUES (24,'menu','delete','Menus::Delete','','','menu-admin','','','off','');
INSERT INTO `requests` VALUES (25,'menu','edit','Menus::Edit','','menus/menu_adminedit.html','','','','off','');
INSERT INTO `requests` VALUES (26,'imgs','save','Images::Save','','','imgs-admin','','imgs-failure','off','');
INSERT INTO `requests` VALUES (27,'imgs','admin','Images::List','','images/image-list.html','','','','off','');
INSERT INTO `requests` VALUES (28,'imgs','failure','','','images/image-failure.html','','','','off','');
INSERT INTO `requests` VALUES (29,'imgs','add','Images::Add','','images/image-edit.html','','','','off','');
INSERT INTO `requests` VALUES (30,'imgs','delete','Images::Delete','','','imgs-admin','','imgs-failure','off','');
INSERT INTO `requests` VALUES (31,'imgs','edit','Images::Edit','','images/image-edit.html','','','','off','');
INSERT INTO `requests` VALUES (32,'hits','admin','Hits::AdminPages','','hits/hits_admin.html','','','','off','');

-- public & admin plugin requests
INSERT INTO `requests` VALUES (33,'arts','save','Site::Save','','','arts-edit','arts-edit','arts-failure','off','');
INSERT INTO `requests` VALUES (34,'arts','admin','Site::Admin','','articles/arts-adminlist.html','','','','off','');
INSERT INTO `requests` VALUES (35,'arts','failure','','','articles/arts-failure.html','','','','off','');
INSERT INTO `requests` VALUES (36,'arts','add','Site::Add','','articles/arts-adminedit.html','','','','off','');
INSERT INTO `requests` VALUES (37,'arts','delete','Site::Delete','','','arts-admin','','arts-failure','off','');
INSERT INTO `requests` VALUES (38,'arts','item','Site::Item','','articles/arts-item.html','','','','off','');
INSERT INTO `requests` VALUES (39,'arts','edit','Site::Edit','','articles/arts-adminedit.html','','','','off','');
INSERT INTO `requests` VALUES (40,'user','add','Users::Add','','users/user-adminedit.html','','','','off','');
INSERT INTO `requests` VALUES (41,'user','acldel','Users::ACLDelete','','','user-acl','user-acl','user-acl','off','');
INSERT INTO `requests` VALUES (42,'user','item','Users::Item','','users/user-item.html','','','','off','');
INSERT INTO `requests` VALUES (43,'user','edit','Users::Edit','','users/user-edit.html','','','','off','');
INSERT INTO `requests` VALUES (44,'user','aclsave','Users::ACLSave','','','user-acl','user-acl','user-acl','off','');
INSERT INTO `requests` VALUES (45,'user','save','Users::Save','','','user-adminedit','user-adminedit','user-failure','off','');
INSERT INTO `requests` VALUES (46,'user','failure','','','users/user-failure.html','','','','off','');
INSERT INTO `requests` VALUES (47,'user','chng','Users::Password','','','user-edit','user-pass','','off','');
INSERT INTO `requests` VALUES (48,'user','logout','Users::Logout','','','home-main','','','off','');
INSERT INTO `requests` VALUES (49,'user','list','Users::UserLists','','users/user-list.html','','','','off','');
INSERT INTO `requests` VALUES (50,'user','admin','Users::Admin','','users/user-adminlist.html','','','','off','');
INSERT INTO `requests` VALUES (51,'user','pass','Users::Name','','users/user-pass.html','','','','off','');
INSERT INTO `requests` VALUES (52,'user','acl','Users::ACL','','users/user-acl.html','','','','off','');
INSERT INTO `requests` VALUES (53,'user','ban','Users::Ban','','','user-admin','','user-failure','off','');
INSERT INTO `requests` VALUES (54,'user','login','','','users/user-login.html','','','','off','');
INSERT INTO `requests` VALUES (55,'user','amend','Users::Save','','','user-edit','user-editerror','user-failure','off','');
INSERT INTO `requests` VALUES (56,'user','logged','Users::Login,Users::Retrieve','','','','user-login','user-login','off','');
INSERT INTO `requests` VALUES (57,'user','delete','Users::Delete','','','user-admin','','user-failure','off','');
INSERT INTO `requests` VALUES (58,'user','adminedit','Users::Edit','','users/user-adminedit.html','','','','off','');
INSERT INTO `requests` VALUES (59,'user','adminpass','Users::AdminPass',NULL,'users/user-adminpass.html','','',NULL,'off',NULL);
INSERT INTO `requests` VALUES (60,'user','adminchng','Users::AdminChng',NULL,'','user-adminedit','user-adminpass',NULL,'off',NULL);
