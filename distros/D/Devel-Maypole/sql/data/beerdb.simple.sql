

INSERT INTO beer (id, brewery, name, abv) VALUES
    (1, 1, "Organic Best Bitter", "4.1");
INSERT INTO brewery (id, name, url) VALUES
    (1, "St Peter's Brewery", "http://www.stpetersbrewery.co.uk/");
INSERT INTO pub (id, name) VALUES (1, "Turf Tavern");
INSERT INTO handpump (id, pub, beer) VALUES (1, 1,1);
