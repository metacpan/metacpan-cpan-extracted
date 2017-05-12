/*
 * Written by Alan Burlinson -- taken from his blog post
 * at <http://blogs.sun.com/alanbur/date/20050909>.
 */

provider perlxs {
    probe sub__entry(char*, char*, int);
    probe sub__return(char*, char*, int);
};
