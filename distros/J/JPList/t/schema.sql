DROP TABLE IF EXISTS "Items";
CREATE TABLE "Items" (
	"Id"			INTEGER PRIMARY KEY AUTOINCREMENT,
	"Title"			VARCHAR(255) NULL,
	"Image"			VARCHAR(255) NULL,
	"Description"	TEXT NULL,
	"Likes"			INTEGER NULL,
	"ViewsNumber"	INTEGER NULL,
	"Keyword1"		VARCHAR(255) NULL,
	"Keyword2"		VARCHAR(255) NULL
);

INSERT INTO "Items" ("Title", "Image", "Description", "Likes", "ViewsNumber", "Keyword1", "Keyword2")  VALUES ('Architecture', '../img/thumbs/arch-2.jpg', 'Architecture is both the process and product of planning, designing and construction. Architectural works, in the material form of buildings, are often perceived as cultural symbols and as works of art. Historical civilizations are often identified with their surviving architectural achievements.', 25, 100, 'Architecture', 'Brown');
		
INSERT INTO "Items" ("Title", "Image", "Description", "Likes", "ViewsNumber", "Keyword1", "Keyword2")  VALUES ('Autumn', '../img/thumbs/autumn-1.jpg', 'Autumn or Fall is one of the four temperate seasons. Autumn marks the transition from summer into winter, in September (Northern Hemisphere) or March (Southern Hemisphere)\r\nwhen the arrival of night becomes noticeably earlier. The equinoxes might be expected to be in the middle of their respective seasons, but temperature lag (caused by the thermal latency of the ground and sea) means that seasons appear later than dates calculated from a purely astronomical perspective.', 12, 330, 'Nature', 'Red');