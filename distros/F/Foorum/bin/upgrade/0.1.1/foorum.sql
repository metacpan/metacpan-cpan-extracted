DROP TABLE `email_setting` ;
CREATE TABLE `user_settings` (
`user_id` INT( 11 ) UNSIGNED NOT NULL DEFAULT '0',
`type` VARCHAR( 48 ) NOT NULL ,
`value` VARCHAR( 48 ) NOT NULL ,
INDEX ( `user_id` )
);
ALTER TABLE `user_settings` ADD PRIMARY KEY ( `user_id` , `type` );