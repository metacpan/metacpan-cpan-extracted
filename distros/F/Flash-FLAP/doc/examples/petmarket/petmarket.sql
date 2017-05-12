-- MySQL dump 8.22
--
-- Host: localhost    Database: petmarket
---------------------------------------------------------
-- Server version	3.23.56

--
-- Table structure for table 'cart_details'
--

CREATE TABLE cart_details (
  cartid varchar(100) default NULL,
  itemid varchar(10) default NULL,
  quantity int(11) default NULL
) TYPE=MyISAM;

--
-- Dumping data for table 'cart_details'
--


--
-- Table structure for table 'category'
--

CREATE TABLE category (
  catid varchar(10) NOT NULL default ''
) TYPE=MyISAM;

--
-- Dumping data for table 'category'
--


INSERT INTO category VALUES ('BIRDS');
INSERT INTO category VALUES ('REPTILES');
INSERT INTO category VALUES ('DOGS');
INSERT INTO category VALUES ('FISH');
INSERT INTO category VALUES ('CATS');

--
-- Table structure for table 'category_details'
--

CREATE TABLE category_details (
  catid varchar(10) NOT NULL default '',
  name varchar(80) NOT NULL default '',
  image varchar(255) default NULL,
  descn varchar(255) default NULL,
  locale varchar(10) NOT NULL default ''
) TYPE=MyISAM;

--
-- Dumping data for table 'category_details'
--


INSERT INTO category_details VALUES ('BIRDS','Birds','birds_icon.gif','','en-US');
INSERT INTO category_details VALUES ('REPTILES','Reptiles','reptiles_icon.gif','','en-US');
INSERT INTO category_details VALUES ('DOGS','Dogs','dogs_icon.gif','','en-US');
INSERT INTO category_details VALUES ('FISH','Fish','fish_icon.gif','','en-US');
INSERT INTO category_details VALUES ('CATS','Cats','cats_icon.gif','','en-US');

--
-- Table structure for table 'item'
--

CREATE TABLE item (
  itemid varchar(10) NOT NULL default '',
  productid varchar(10) NOT NULL default ''
) TYPE=MyISAM;

--
-- Dumping data for table 'item'
--


INSERT INTO item VALUES ('EST-3','FI-SW-02');
INSERT INTO item VALUES ('EST-15','FL-DSH-01');
INSERT INTO item VALUES ('EST-19','AV-SB-02');
INSERT INTO item VALUES ('EST-7','K9-BD-01');
INSERT INTO item VALUES ('EST-27','K9-CW-01');
INSERT INTO item VALUES ('EST-26','K9-CW-01');
INSERT INTO item VALUES ('EST-6','K9-BD-01');
INSERT INTO item VALUES ('EST-8','K9-PO-02');
INSERT INTO item VALUES ('EST-28','K9-RT-01');
INSERT INTO item VALUES ('EST-22','K9-RT-02');
INSERT INTO item VALUES ('EST-25','K9-RT-02');
INSERT INTO item VALUES ('EST-16','FL-DLH-02');
INSERT INTO item VALUES ('EST-10','K9-DL-01');
INSERT INTO item VALUES ('EST-2','FI-SW-01');
INSERT INTO item VALUES ('EST-18','AV-CB-01');
INSERT INTO item VALUES ('EST-17','FL-DLH-02');
INSERT INTO item VALUES ('EST-13','RP-LI-02');
INSERT INTO item VALUES ('EST-4','FI-FW-01');
INSERT INTO item VALUES ('EST-23','K9-RT-02');
INSERT INTO item VALUES ('EST-5','FI-FW-01');
INSERT INTO item VALUES ('EST-12','RP-SN-01');
INSERT INTO item VALUES ('EST-21','FI-FW-02');
INSERT INTO item VALUES ('EST-1','FI-SW-01');
INSERT INTO item VALUES ('EST-9','K9-DL-01');
INSERT INTO item VALUES ('EST-20','FI-FW-02');
INSERT INTO item VALUES ('EST-14','FL-DSH-01');
INSERT INTO item VALUES ('EST-11','RP-SN-01');
INSERT INTO item VALUES ('EST-24','K9-RT-02');

--
-- Table structure for table 'item_details'
--

CREATE TABLE item_details (
  itemid varchar(10) NOT NULL default '',
  listprice decimal(10,2) NOT NULL default '0.00',
  unitcost decimal(10,2) NOT NULL default '0.00',
  locale varchar(10) NOT NULL default '',
  image varchar(255) NOT NULL default '',
  descn varchar(255) NOT NULL default '',
  attr1 varchar(80) default NULL,
  attr2 varchar(80) default NULL,
  attr3 varchar(80) default NULL,
  attr4 varchar(80) default NULL,
  attr5 varchar(80) default NULL
) TYPE=MyISAM;

--
-- Dumping data for table 'item_details'
--


INSERT INTO item_details VALUES ('EST-3',0.00,12.00,'en-US','fish4.gif','Salt Water fish from Australia','Toothless','Mean','','','');
INSERT INTO item_details VALUES ('EST-15',0.00,12.00,'en-US','cat3.gif','Great for reducing mouse populations','With tail','','','','');
INSERT INTO item_details VALUES ('EST-19',0.00,2.00,'en-US','bird1.gif','Great stress reliever','Adult Male','','','','');
INSERT INTO item_details VALUES ('EST-7',0.00,12.00,'en-US','dog2.gif','Friendly dog from England','Female Puppy','','','','');
INSERT INTO item_details VALUES ('EST-27',0.00,90.00,'en-US','dog4.gif','Great companion dog','Adult Female','','','','');
INSERT INTO item_details VALUES ('EST-26',0.00,92.00,'en-US','dog4.gif','Little yapper','Adult Male','','','','');
INSERT INTO item_details VALUES ('EST-6',0.00,12.00,'en-US','dog2.gif','Friendly dog from England','Male Adult','','','','');
INSERT INTO item_details VALUES ('EST-8',0.00,12.00,'en-US','dog6.gif','Cute dog from France','Male Puppy','','','','');
INSERT INTO item_details VALUES ('EST-28',0.00,90.00,'en-US','dog1.gif','Great family dog','Adult Female','','','','');
INSERT INTO item_details VALUES ('EST-22',0.00,100.00,'en-US','dog5.gif','Great hunting dog','Adult Male','','','','');
INSERT INTO item_details VALUES ('EST-25',0.00,90.00,'en-US','dog5.gif','Great hunting dog','Female Puppy','','','','');
INSERT INTO item_details VALUES ('EST-16',0.00,12.00,'en-US','cat1.gif','Friendly house cat, doubles as a princess','Adult Female','','','','');
INSERT INTO item_details VALUES ('EST-10',0.00,12.00,'en-US','dog5.gif','Great dog for a Fire Station','Spotted Adult Female','','','','');
INSERT INTO item_details VALUES ('EST-2',0.00,10.00,'en-US','fish3.gif','Fresh Water fish from Japan','Small','','','','');
INSERT INTO item_details VALUES ('EST-18',0.00,92.00,'en-US','bird4.gif','Great companion for up to 75 years','Adult Male','','','','');
INSERT INTO item_details VALUES ('EST-17',0.00,12.00,'en-US','cat1.gif','Friendly house cat, doubles as a prince','Adult Male','','','','');
INSERT INTO item_details VALUES ('EST-13',0.00,11.10,'en-US','lizard2.gif','Friendly green friend','Green Adult','','','','');
INSERT INTO item_details VALUES ('EST-4',0.00,12.00,'en-US','fish3.gif','Fresh Water fish from Japan','Spotted','','','','');
INSERT INTO item_details VALUES ('EST-23',0.00,100.00,'en-US','dog5.gif','Great hunting dog','Adult Female','','','','');
INSERT INTO item_details VALUES ('EST-5',0.00,12.00,'en-US','fish3.gif','Fresh Water fish from Japan','Spotless','','','','');
INSERT INTO item_details VALUES ('EST-12',0.00,12.00,'en-US','lizard3.gif','Doubles as a watch dog','Rattleless','','','','');
INSERT INTO item_details VALUES ('EST-21',0.00,1.00,'en-US','fish2.gif','Fresh Water fish from China','Adult Female','','','','');
INSERT INTO item_details VALUES ('EST-1',0.00,10.00,'en-US','fish3.gif','Fresh Water fish from Japan','Large','Cuddly','','','');
INSERT INTO item_details VALUES ('EST-9',0.00,12.00,'en-US','dog5.gif','Great dog for a Fire Station','Spotless Male Puppy','','','','');
INSERT INTO item_details VALUES ('EST-20',0.00,2.00,'en-US','fish2.gif','Fresh Water fish from China','Adult Male','','','','');
INSERT INTO item_details VALUES ('EST-14',0.00,12.00,'en-US','cat3.gif','Great for reducing mouse populations','Tailless','','','','');
INSERT INTO item_details VALUES ('EST-11',0.00,12.00,'en-US','lizard3.gif','More Bark than bite','Venomless','','','','');
INSERT INTO item_details VALUES ('EST-24',0.00,92.00,'en-US','dog5.gif','Great addition to a family','Male Puppy','','','','');

--
-- Table structure for table 'product'
--

CREATE TABLE product (
  productid varchar(10) NOT NULL default '',
  catid varchar(10) NOT NULL default ''
) TYPE=MyISAM;

--
-- Dumping data for table 'product'
--


INSERT INTO product VALUES ('K9-RT-01','DOGS');
INSERT INTO product VALUES ('K9-DL-01','DOGS');
INSERT INTO product VALUES ('FI-SW-01','FISH');
INSERT INTO product VALUES ('FI-FW-02','FISH');
INSERT INTO product VALUES ('K9-BD-01','DOGS');
INSERT INTO product VALUES ('K9-PO-02','DOGS');
INSERT INTO product VALUES ('FL-DLH-02','CATS');
INSERT INTO product VALUES ('K9-RT-02','DOGS');
INSERT INTO product VALUES ('AV-CB-01','BIRDS');
INSERT INTO product VALUES ('AV-SB-02','BIRDS');
INSERT INTO product VALUES ('FL-DSH-01','CATS');
INSERT INTO product VALUES ('RP-SN-01','REPTILES');
INSERT INTO product VALUES ('RP-LI-02','REPTILES');
INSERT INTO product VALUES ('FI-SW-02','FISH');
INSERT INTO product VALUES ('FI-FW-01','FISH');
INSERT INTO product VALUES ('K9-CW-01','DOGS');

--
-- Table structure for table 'product_details'
--

CREATE TABLE product_details (
  productid varchar(10) NOT NULL default '',
  locale varchar(10) NOT NULL default '',
  name varchar(80) NOT NULL default '',
  image varchar(255) default NULL,
  descn varchar(255) default NULL
) TYPE=MyISAM;

--
-- Dumping data for table 'product_details'
--


INSERT INTO product_details VALUES ('K9-RT-01','en-US','Golden Retriever','dog1.gif','Great family dog');
INSERT INTO product_details VALUES ('K9-DL-01','en-US','Dalmation','dog5.gif','Great dog for a Fire Station');
INSERT INTO product_details VALUES ('FI-SW-01','en-US','Angelfish','fish1.jpg','Salt Water fish from Australia');
INSERT INTO product_details VALUES ('FI-FW-02','en-US','Goldfish','fish2.gif','Fresh Water fish from China');
INSERT INTO product_details VALUES ('K9-BD-01','en-US','Bulldog','dog2.gif','Friendly dog from England');
INSERT INTO product_details VALUES ('K9-PO-02','en-US','Poodle','dog6.gif','Cute dog from France');
INSERT INTO product_details VALUES ('FL-DLH-02','en-US','Persian','cat1.gif','Friendly house cat, doubles as a princess');
INSERT INTO product_details VALUES ('K9-RT-02','en-US','Labrador Retriever','dog5.gif','Great hunting dog');
INSERT INTO product_details VALUES ('AV-CB-01','en-US','Amazon Parrot','bird4.gif','Great companion for up to 75 years');
INSERT INTO product_details VALUES ('AV-SB-02','en-US','Finch','bird1.gif','Great stress reliever');
INSERT INTO product_details VALUES ('FL-DSH-01','en-US','Manx','cat3.gif','Great for reducing mouse populations');
INSERT INTO product_details VALUES ('RP-SN-01','en-US','Rattlesnake','lizard3.gif','Doubles as a watch dog');
INSERT INTO product_details VALUES ('RP-LI-02','en-US','Iguana','lizard2.gif','Friendly green friend');
INSERT INTO product_details VALUES ('FI-SW-02','en-US','Tiger Shark','fish4.gif','Salt Water fish from Australia');
INSERT INTO product_details VALUES ('FI-FW-01','en-US','Koi','fish3.gif','Fresh Water fish from Japan');
INSERT INTO product_details VALUES ('K9-CW-01','en-US','Chihuahua','dog4.gif','Great companion dog');

--
-- Table structure for table 'user_details'
--

CREATE TABLE user_details (
  email varchar(50) default NULL,
  password varchar(50) default NULL,
  firstname varchar(50) default NULL,
  lastname varchar(50) default NULL,
  homestreet1 varchar(50) default NULL,
  homestreet2 varchar(50) default NULL,
  homecity varchar(50) default NULL,
  homestate char(2) default NULL,
  homecountry varchar(50) default NULL,
  homezip varchar(10) default NULL,
  homephone varchar(20) default NULL,
  shippingstreet1 varchar(50) default NULL,
  shippingstreet2 varchar(50) default NULL,
  shippingcity varchar(50) default NULL,
  shippingcountry varchar(50) default NULL,
  shippingzip varchar(10) default NULL,
  shippingphone varchar(20) default NULL,
  creditcardnumber varchar(50) default NULL,
  creditcardtype varchar(50) default NULL,
  creditcardexpiry varchar(50) default NULL
) TYPE=MyISAM;

--
-- Dumping data for table 'user_details'
--


