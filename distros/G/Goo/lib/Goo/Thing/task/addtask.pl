#!/usr/bin/perl
# -*- Mode: cperl; mode: folding; -*-

##############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2004
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     addtask.pl
# Description:  Add a new task to the goo database
#
# Date          Change
# -----------------------------------------------------------------------------
#
###############################################################################

use strict;

use lib "$ENV{GOOBASE}/shared/bin";

use CGIScript;
use GooDatabase;

my $cgi = CGIScript->new();


my $query = GooDatabase::prepareSQL(<<EOSQL);

    insert  into task ( title,
                        description,
                        requestedby,
                        importance,
						company,
                        status,
                        requestedon)
    values            (?, ?, ?, ?, ?, "pending", now())

EOSQL

GooDatabase::bindParam($query, 1, $cgi->{title});
GooDatabase::bindParam($query, 2, $cgi->{description});
GooDatabase::bindParam($query, 3, $cgi->{requestedby});
GooDatabase::bindParam($query, 4, $cgi->{importance});
GooDatabase::bindParam($query, 5, $cgi->{company});

# what is the pain associated with this task???
GooDatabase::execute($query);


print <<OUT;
Content-type: text/html

<html>
<head>
</head>
<body>

<h1>New Task Added</h1>
<p>
<h2>$cgi->{title}</h2>
<p>
<a href="/addtask.html">Enter another task?</a>
</body>
</html>

OUT


