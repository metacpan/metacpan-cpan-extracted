BEGIN TRANSACTION;
CREATE table book (
    id INTEGER PRIMARY KEY,
    isbn varchar(100),
    title varchar(100),
    author varchar(100),
    publisher varchar(100),
    pages INTEGER,
    year INTEGER,
    format INTEGER REFERENCES format,
    borrower INTEGER REFERENCES borrower,
    borrowed varchar(100)
);
INSERT INTO book VALUES(1,'0-7475-5100-6','Harry Potter and the Order of the Phoenix','J.K. Rowling','Boomsbury',766,2001,1,1,'');
INSERT INTO book VALUES(2,'9 788256006199','Idioten','Fyodor Dostoyevsky','Interbook',303,1901,2,2,'2004-00-10');
INSERT INTO book VALUES(3,'0060733357','The Confusion','Neil Stephenson','Harper Perennial',NULL,NULL,NULL,NULL,NULL);
INSERT INTO book VALUES(4,'978-1563890116','The Sandman Vol. 1: Preludes and Nocturnes','Neil Gaiman','Vertigo', 240,1993,4,2,'2008-01-04');

CREATE TABLE borrower (
    id INTEGER PRIMARY KEY,
    name varchar(100),
    phone varchar(20),
    url varchar(100),
    email varchar(100)
);
INSERT INTO borrower VALUES(1,'In Shelf',NULL,'','');
INSERT INTO borrower VALUES(2,'Mark Trout','46 99 23 97','http://www.somewhere.com/','mst@somehwere.com');
INSERT INTO borrower VALUES(3,'John Doe', '234-345-12345','http://nowhere.com/','doe@gmail.com');
INSERT INTO borrower VALUES(4,'Gigi LePew','456-234-9876','http://lepew.org/','gigi@email.com');

CREATE TABLE format (
    id INTEGER PRIMARY KEY,
    name varchar(100)
);
INSERT INTO format VALUES(1,'Paperback');
INSERT INTO format VALUES(2,'Hardcover');
INSERT INTO format VALUES(3,'Comic');
INSERT INTO format VALUES(4,'Graphic Novel');
INSERT INTO format VALUES(5,'EBook');
INSERT INTO format VALUES(6,'Trade');


CREATE TABLE genre (
    id INTEGER PRIMARY KEY,
    name varchar(100)
);

INSERT INTO genre VALUES(1,'Sci-Fi');
INSERT INTO genre VALUES(2,'Computers');
INSERT INTO genre VALUES(3,'Mystery');
INSERT INTO genre VALUES(4,'Historical');
INSERT INTO genre VALUES(5,'Fantasy');
INSERT INTO genre VALUES(6,'Comedy');
INSERT INTO genre VALUES(7,'Romance');
INSERT INTO genre VALUES(8,'Suspense');
INSERT INTO genre VALUES(9,'Drama');
COMMIT;

CREATE TABLE books_genres (
   book_id INTEGER REFERENCES book,
   genre_id INTEGER REFERENCES genre,
   primary key (book_id, genre_id)
);

INSERT INTO books_genres VALUES(1, 5);
INSERT INTO books_genres VALUES(1, 3);
INSERT INTO books_genres VALUES(2, 9);


