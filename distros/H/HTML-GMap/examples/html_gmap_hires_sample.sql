-- Sample SQL table and data for HTML::GMap
-- Author: Payan Canaran <pcanaran@cpan.org>
-- Copyright (c) 2006-2007 Cold Spring Harbor Laboratory
-- Version 0.06

DROP TABLE IF EXISTS `html_gmap_hires_sample`;

CREATE TABLE `html_gmap_hires_sample` (
    `id`                          int(11) NOT NULL auto_increment,
    `latitude`                    double,
    `longitude`                   double,
    `name`                        varchar(30),
    `pharmacy`                    char(3),  
    `open24`                      char(3),
    PRIMARY KEY                 (`id`),
    KEY                         (`latitude`),
    KEY                         (`longitude`),
    KEY                         (`pharmacy`),
    KEY                         (`open24`)
    ) ENGINE=MyISAM;

INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.9794750983438", "-75.3358135014879", "Store #1", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.3620809291262", "-76.8109634416761", "Store #2", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.2459348882374", "-77.5112839664771", "Store #3", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.2741808370356", "-77.5304390812752", "Store #4", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.9544462044156", "-78.4300768752618", "Store #5", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.595412998129", "-77.4894701017018", "Store #6", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.4123757624479", "-75.3538259414552", "Store #7", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.8228002188986", "-76.1726336249837", "Store #8", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.2181932628239", "-76.1174990324122", "Store #9", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.030127276133", "-75.0526891949226", "Store #10", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.8095449807552", "-76.5346705338457", "Store #11", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.56927092304", "-76.6103664462757", "Store #12", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.7159877716266", "-78.3762762278706", "Store #13", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.5920655551591", "-77.1980820647089", "Store #14", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.6880753866278", "-76.0565176766634", "Store #15", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.8583417430953", "-78.8011749047093", "Store #16", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.9155046180972", "-77.2181768539241", "Store #17", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.493040464106", "-75.7463418826438", "Store #18", "Yes", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.4005444191092", "-78.3431955163287", "Store #19", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.3650714895707", "-76.2780510121519", "Store #20", "Yes", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.218986766835", "-75.3229675571591", "Store #21", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.5828500103765", "-75.6698016990602", "Store #22", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.8793736642101", "-78.6063863342986", "Store #23", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.2362112072497", "-75.1581961630051", "Store #24", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.2822702994379", "-75.1022827147796", "Store #25", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.9616680980652", "-75.4838796029531", "Store #26", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.8848700078621", "-78.4464833280722", "Store #27", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.1677436191637", "-77.194500473804", "Store #28", "Yes", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.5922323057379", "-75.5523122703001", "Store #29", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.8293735227103", "-76.1109359912664", "Store #30", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.6249708904344", "-78.5469532515719", "Store #31", "Yes", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.6451422971234", "-75.4791217321919", "Store #32", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.1542241265988", "-75.2546829286149", "Store #33", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.0483799426067", "-78.3259179475554", "Store #34", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.8482561628133", "-78.3215799148993", "Store #35", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.0729130588142", "-78.4085389552701", "Store #36", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.6410524482768", "-78.8849077104404", "Store #37", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.3965293266818", "-75.8931657300234", "Store #38", "Yes", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.0117890440428", "-75.3739635434656", "Store #39", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.019980091453", "-76.5194555573223", "Store #40", "Yes", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.855070748343", "-75.5877788661343", "Store #41", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.9866113789343", "-78.5037563689344", "Store #42", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.62534868053", "-76.628650996498", "Store #43", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.307479302008", "-77.8049271269142", "Store #44", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.854943593169", "-76.5790791488884", "Store #45", "Yes", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.8290714394352", "-77.6227593733996", "Store #46", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.3736168068105", "-75.9932718449202", "Store #47", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.165521393981", "-76.1200888133682", "Store #48", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.5986462869746", "-78.3329864472972", "Store #49", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.014469361891", "-75.35577954754", "Store #50", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.1178810078785", "-76.4110553086084", "Store #51", "Yes", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.1854871707523", "-76.2868573226132", "Store #52", "Yes", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.4542623724384", "-76.7145467773015", "Store #53", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.4922518677697", "-75.4441619160232", "Store #54", "Yes", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.3788170830775", "-77.1631030530223", "Store #55", "Yes", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.2944175654876", "-78.5069825224088", "Store #56", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.4301414828703", "-76.4165906335062", "Store #57", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.9224008769897", "-78.4982337589759", "Store #58", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.4019130115553", "-78.2797928452105", "Store #59", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.4780608976077", "-75.6928236569451", "Store #60", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.4759800459473", "-75.060467699874", "Store #61", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.57652031517", "-78.5779587562704", "Store #62", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.4070970192799", "-76.920688069192", "Store #63", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.4791398558212", "-76.3252251708174", "Store #64", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.7063873390107", "-76.3199749197939", "Store #65", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.7649238974447", "-77.2303782411873", "Store #66", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.1241322476188", "-77.5823281007115", "Store #67", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.1974007077187", "-76.4478671423757", "Store #68", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.8984993959272", "-77.4278529255242", "Store #69", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.7662863888379", "-78.0932145634522", "Store #70", "Yes", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.2153405234807", "-76.9932745413705", "Store #71", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.0180072359304", "-75.4074653264494", "Store #72", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.1152032655111", "-75.4242258270111", "Store #73", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.7364208412031", "-76.1740115616481", "Store #74", "Yes", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.6872177310198", "-75.5557883121332", "Store #75", "Yes", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.7948419008455", "-76.9491958064468", "Store #76", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.8055341215103", "-75.506359360082", "Store #77", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.5727443067235", "-78.9141871450022", "Store #78", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.8925032849017", "-78.1935126062074", "Store #79", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.7152767298947", "-76.2767192558296", "Store #80", "Yes", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.2338077241534", "-75.8391123940138", "Store #81", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.2109945279759", "-75.1473729845484", "Store #82", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.2242662051334", "-78.4645367012999", "Store #83", "Yes", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.7729764333949", "-76.686179808963", "Store #84", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.5890507332607", "-78.1854567984764", "Store #85", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.3307601045565", "-75.0614163136641", "Store #86", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.1035702934541", "-78.7992156312482", "Store #87", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.0752962469561", "-78.3835535413397", "Store #88", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.6262913729167", "-76.7164406698508", "Store #89", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.9463866362693", "-75.2734188379823", "Store #90", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.3622809112899", "-78.7221207170255", "Store #91", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.7118370004516", "-77.09472155918", "Store #92", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.1912729477057", "-76.359969916923", "Store #93", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.8598213428773", "-78.127187754679", "Store #94", "Yes", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.6225758592702", "-77.9174959571221", "Store #95", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.41071991355", "-77.0776426984059", "Store #96", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.4801527105092", "-75.0477832059515", "Store #97", "No", "Yes");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.4519586604157", "-77.3224738811351", "Store #98", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("41.7747228583065", "-75.9975952773011", "Store #99", "No", "No");
INSERT INTO html_gmap_hires_sample (latitude, longitude, name, pharmacy, open24) VALUES ("40.7091436178098", "-78.1460008329913", "Store #100", "No", "No");
