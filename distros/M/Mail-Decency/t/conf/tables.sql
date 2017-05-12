

--
-- CWL - custom white list
--

CREATE TABLE cwl_ips (
    id INTEGER PRIMARY KEY,
    recipient_domain varchar( 255 ),
    sender_ip varchar( 39 )
);
CREATE UNIQUE INDEX cwl_ips_uk ON cwl_ips( recipient_domain, sender_ip );

CREATE TABLE cwl_domains (
    id INTEGER PRIMARY KEY,
    recipient_domain varchar( 255 ),
    sender_domain varchar( 255 )
);
CREATE UNIQUE INDEX cwl_domains_uk ON cwl_domains( recipient_domain, sender_domain );

CREATE TABLE cwl_addresses (
    id INTEGER PRIMARY KEY,
    recipient_domain varchar( 255 ),
    sender_address varchar( 255 )
);
CREATE UNIQUE INDEX cwl_addresses_uk ON cwl_addresses( recipient_domain, sender_address );




--
-- CBL - custom black list
--


CREATE TABLE cbl_ips (
    id INTEGER PRIMARY KEY,
    recipient_domain varchar( 255 ),
    sender_ip varchar( 39 )
);
CREATE UNIQUE INDEX cbl_ips_uk ON cbl_ips( recipient_domain, sender_ip );

CREATE TABLE cbl_domains (
    id INTEGER PRIMARY KEY,
    recipient_domain varchar( 255 ),
    sender_domain varchar( 255 )
);
CREATE UNIQUE INDEX cbl_domains_uk ON cbl_domains( recipient_domain, sender_domain );

CREATE TABLE cbl_addresses (
    id INTEGER PRIMARY KEY,
    recipient_domain varchar( 255 ),
    sender_address varchar( 255 )
);
CREATE UNIQUE INDEX cbl_addresses_uk ON cbl_addresses( recipient_domain, sender_address );




--
-- Greylist
--


-- contains all sender host ips, which are or are to be
--  whitelisted due to lot's of positives
CREATE TABLE greylist_client_addresss (
    id INTEGER PRIMARY KEY,
    client_address VARCHAR( 39 ),
    data TEXT
);
CREATE UNIQUE INDEX greylist_client_addresss_uk ON greylist_client_addresss( client_address );

-- contains all sender_domains, which are or are to be
--  whitelisted due to lot's of positives
CREATE TABLE greylist_sender_domain (
    id INTEGER PRIMARY KEY,
    sender_domain varchar( 255 ),
    data TEXT
);
CREATE UNIQUE INDEX greylist_sender_domain_uk ON greylist_sender_domain( sender_domain );

-- contains all (sender -> recipient) address pairs which
--  are used to allow the second send attempt
CREATE TABLE greylist_sender_recipient (
    id INTEGER PRIMARY KEY,
    sender_address varchar( 255 ),
    recipient_address varchar( 255 ),
    data TEXT
);
CREATE UNIQUE INDEX greylist_sender_recipient_uk ON greylist_sender_recipient( sender_address, recipient_address );



--
-- Honeypot
--


CREATE TABLE honeypot_client_address (
    id INTEGER PRIMARY KEY,
    client_address varchar( 39 )
);
CREATE UNIQUE INDEX honeypot_client_address_uk ON honeypot_client_address( client_address );





--
-- Throttle
--

CREATE TABLE throttle_client_address (
    id INTEGER PRIMARY KEY,
    client_address VARCHAR( 255 ),
    interval INTEGER,
    maximum INTEGER,
    account VARCHAR( 25 )
);
CREATE UNIQUE INDEX throttle_client_address_uk ON throttle_client_address( client_address, interval );

CREATE TABLE throttle_sender_domain (
    id INTEGER PRIMARY KEY,
    sender_domain VARCHAR( 255 ),
    interval INTEGER,
    maximum INTEGER,
    account VARCHAR( 25 )
);
CREATE UNIQUE INDEX throttle_sender_domain_uk ON throttle_sender_domain( sender_domain, interval );

CREATE TABLE throttle_sender_address(
    id INTEGER PRIMARY KEY,
    sender_address VARCHAR( 255 ),
    interval INTEGER,
    maximum INTEGER,
    account VARCHAR( 25 )
);
CREATE UNIQUE INDEX throttle_sender_address_uk ON throttle_sender_address( sender_address, interval );

CREATE TABLE throttle_sasl_username(
    id INTEGER PRIMARY KEY,
    sasl_username VARCHAR( 255 ),
    interval INTEGER,
    maximum INTEGER,
    account VARCHAR( 25 )
);
CREATE UNIQUE INDEX throttle_sasl_username_uk ON throttle_sasl_username( sasl_username, interval );

CREATE TABLE throttle_recipient_domain(
    id INTEGER PRIMARY KEY,
    recipient_domain VARCHAR( 255 ),
    interval INTEGER,
    maximum INTEGER,
    account VARCHAR( 25 )
);
CREATE UNIQUE INDEX throttle_recipient_domain_uk ON throttle_recipient_domain( recipient_domain, interval );

CREATE TABLE throttle_recipient_address(
    id INTEGER PRIMARY KEY,
    recipient_address VARCHAR( 255 ),
    interval INTEGER,
    maximum INTEGER,
    account VARCHAR( 25 )
);
CREATE UNIQUE INDEX throttle_recipient_address_uk ON throttle_recipient_address( recipient_address, interval );

CREATE TABLE throttle_account(
    id INTEGER PRIMARY KEY,
    account VARCHAR( 255 ),
    interval INTEGER,
    maximum INTEGER
);
CREATE UNIQUE INDEX throttle_account_uk ON throttle_account( account, interval );

