[![Linux Build Status](https://travis-ci.org/nigelhorne/HTML-SocialMedia.svg?branch=master)](https://travis-ci.org/nigelhorne/HTML-SocialMedia)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/7wrih4a1xt96jk72/branch/master?svg=true)](https://ci.appveyor.com/project/nigelhorne/html-socialmedia/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/HTML-SocialMedia/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/HTML-SocialMedia?branch=master)
[![Dependency Status](https://dependencyci.com/github/nigelhorne/HTML-SocialMedia/badge)](https://dependencyci.com/github/nigelhorne/HTML-SocialMedia)

# NAME

HTML::SocialMedia - Put social media links onto your website

# VERSION

Version 0.28

# SYNOPSIS

Many websites these days have links and buttons into social media sites.
This module eases links into Twitter, Facebook and Google's PlusOne.

    use HTML::SocialMedia;
    my $sm = HTML::SocialMedia->new();
    # ...

The language of the text displayed will depend on the client's choice, making
HTML::SocialMedia ideal for running on multilingual sites.

Takes optional parameter logger, an object which is used for warnings and
traces.
This logger object is an object that understands warn() and trace() messages,
such as a [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) object.

Takes optional parameter cache, an object which is used to cache country
lookups.
This cache object is an object that understands get() and set() messages,
such as an [CHI](https://metacpan.org/pod/CHI) object.

Takes optional parameter lingua, which is a [CGI::Lingua](https://metacpan.org/pod/CGI%3A%3ALingua) object.

# SUBROUTINES/METHODS

## new

Creates a HTML::SocialMedia object.

    use HTML::SocialMedia;
    my $sm = HTML::SocialMedia->new(twitter => 'example');
    # ...

### Optional parameters

twitter: twitter account name
twitter\_related: array of 2 elements - the name and description of a related account
cache: This object will be an instantiation of a class that understands get and
set, such as [CHI](https://metacpan.org/pod/CHI).
info: Object which understands host\_name messages, such as [CGI::Info](https://metacpan.org/pod/CGI%3A%3AInfo).

## as\_string

Returns the HTML to be added to your website.
HTML::SocialMedia uses [CGI::Lingua](https://metacpan.org/pod/CGI%3A%3ALingua) to try to ensure that the text printed is
in the language of the user.

    use HTML::SocialMedia;
    my $sm = HTML::SocialMedia->new(
        twitter => 'mytwittername',
        twitter_related => [ 'someonelikeme', 'another twitter feed' ]
    );

    print "Content-type: text/html\n\n";

    print '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">';
    print '<HTML><HEAD></HEAD><BODY>';

    print $sm->as_string(
        twitter_follow_button => 1,
        twitter_tweet_button => 1,      # button to tweet this page
        facebook_like_button => 1,
        facebook_share_button => 1,
        linkedin_share_button => 1,
        google_plusone => 1,
        reddit_button => 1,
        align => 'right',
    );

    print '</BODY></HTML>';
    print "\n";

### Optional parameters

twitter\_follow\_button: add a button to follow the account

twitter\_tweet\_button: add a button to tweet this page

facebook\_like\_button: add a Facebook like button

facebook\_share\_button: add a Facebook share button

linkedin\_share\_button: add a LinkedIn share button

google\_plusone: add a Google +1 button

reddit\_button: add a Reddit button

align: argument to &lt;p> HTML tag

## render

Synonym for as\_string.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

When adding a FaceBook like button, you may find performance improves a lot if
you use [HTTP::Cache::Transparent](https://metacpan.org/pod/HTTP%3A%3ACache%3A%3ATransparent).

Please report any bugs or feature requests to `bug-html-socialmedia at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-SocialMedia](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-SocialMedia).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Would be good to have
    my ($head, $body) = $sm->onload\_render();

# SEE ALSO

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::SocialMedia

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-SocialMedia](http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-SocialMedia)

- CPAN Ratings

    [http://cpanratings.perl.org/d/HTML-SocialMedia](http://cpanratings.perl.org/d/HTML-SocialMedia)

- Search CPAN

    [http://search.cpan.org/dist/HTML-SocialMedia/](http://search.cpan.org/dist/HTML-SocialMedia/)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2011-2020 Nigel Horne.

This program is released under the following licence: GPL2
