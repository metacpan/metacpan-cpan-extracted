# NAME

Facebook - The try for a Facebook SDK in Perl

# SYNOPSIS

  use Facebook;

  my $fb = Facebook->new(
    app_id => $app_id,
    secret => $secret,
  );

  use Facebook::Cookie;

  my $fb = Facebook->new(
    cookie => Facebook::Cookie->new(
      app_id => $app_id,
      secret => $secret,
      cookie => $cookie_as_text,
    ),
  );
  

  # You need to have Facebook::Graph installed so that this works
  my $gettys_facebook_profile = $fb->graph->query
    ->find(100001153174797)
    ->include_metadata
    ->request
    ->as_hashref;

# DESCRIPTION

__If you are new to Facebook application development in Perl please read [Facebook::Manual](http://search.cpan.org/perldoc?Facebook::Manual)!__

This package reflects an instance for your application. Depending on what API of it you use, you require to install the
needed distributions or provide alternative packages yourself.

# METHODS

## $obj->graph

- Arguments: None

- Return value: Object

__If you want to use this, you need to install [Facebook::Graph](http://search.cpan.org/perldoc?Facebook::Graph)!__

Returns an instance of the graph_class (by default this is [Facebook::Graph](http://search.cpan.org/perldoc?Facebook::Graph))

## $obj->rest

- Arguments: None

- Return value: Object

__If you want to use this, you need to install [WWW::Facebook::API](http://search.cpan.org/perldoc?WWW::Facebook::API)!__

Returns an instance of the rest_class (by default this is [WWW::Facebook::API](http://search.cpan.org/perldoc?WWW::Facebook::API))

# LIMITATIONS

# TROUBLESHOOTING

# SUPPORT

IRC

  Join #facebook on irc.perl.org.

Repository

  http://github.com/Getty/p5-facebook
  Pull request and additional contributors are welcome
 

Issue Tracker

  http://github.com/Getty/p5-facebook/issues

# AUTHOR

Torsten Raudssus <torsten@raudssus.de> (http://www.raudssus.de/)

# CONTRIBUTORS

# COPYRIGHT

Copyright (c) 2010 the Facebook L</AUTHOR> and L</CONTRIBUTORS> as
listed on [Facebook](http://search.cpan.org/perldoc?Facebook) and all other packages in this distribution.

# LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
