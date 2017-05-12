package Inline::WebChat;
$VERSION = '0.62';
require Inline;
@ISA = qw(Inline);
use strict;
use Carp;
use WWW::Chat::Processor;


# Register as in an Inline Language Support Module (ILSM)
sub register {
    return {
	    language => 'WebChat',
	    aliases => ['webchat'],
	    type => 'interpreted',
	    suffix => 'wc',
	   };
}

# print out a warning
sub usage_config { 
    my $key = shift;
    "'$key' is not a valid config option for Inline::WebChat\n";
}


# validate the config options
sub validate {
    my $o = shift;
    while (@_) {
	my ($key, $value) = splice @_, 0, 2;
	croak usage_config($key);
    }
}

# parse and process WebChat stuff
sub build {
    my $o = shift;

    # parse the code
    my $code = WWW::Chat::Processor::parse($o->{API}{code});
    croak "Foo build failed:\n$@" if $@;
    
    # find the path
    my $path = "$o->{API}{install_lib}/auto/$o->{API}{modpname}";
    my $obj = $o->{API}{location};

    # check to see it's valid and if not, make a new path
    $o->mkpath($path) unless -d $path;

    # and dump the code ...
    open FOO_OBJ, "> $obj"
      or croak "Can't open $obj for output\n$!";
    print FOO_OBJ $code;
    close \*FOO_OBJ;
}


# now load it back up again
sub load {
    my $o = shift;
    
    # find out where it is
    my $obj = $o->{API}{location};

    # read it in
    open FOO_OBJ, "< $obj"
      or croak "Can't open $obj for output\n$!";
    my $code = join '', <FOO_OBJ>;
    close \*FOO_OBJ;

    # and run the code :)
    eval "package $o->{API}{pkg};\n$code";
    croak "Unable to load WebChat module $obj:\n$@" if $@;
}

sub info {
    my $o = shift;
    my $text = <<'END';
This allows you to embed WebChat script in your 
Perl scripts easily. WebChat is an Expect type
language that makes it easy to fetch and 
manipulate web pages and their forms. See the 
webchatpp or WWW::Chat man pages for more details
END
}

1;

__END__

=pod 

=head1 NAME

Inline::WebChat - mix Perl and WebChat in a Perl script

=head1 SYNOPSIS

use Inline WebChat;
use Data::Dumper;

my @site_links = get_site ('http://www.perl.com');

print Dumper @site_links;

__END__

__WebChat__

sub get_site 
{

	my $site = shift;
	GET $site
	return @links;
}



=head1 DESCRIPTION

C<Inline::WebChat> is a module for letting you embed WebChat scripts in your Perl scripts.

Why would you wnat to do this? Well, Gisle Aas' WebChat is an Expect type language that 
fetches and manipulates web pages and their forms. For example you can do stuff like 

        GET http://www.perl.com
           EXPECT OK && /perl/
           GET not_there.html
              EXPECT ERROR
           BACK
        BACK

... and ...

        GET http://www.altavista.com
        	EXPECT OK
        	F q=Gisle
        	CLICK
        	EXPECT OK && /Gisle Aas/

Which is obviously a lot easier than hand rolling your own code with C<LWP> and C<HTML::Forms> ...

... which is exactly what webchat does - take your WebChat script and convert it to pure Perl. Which is 
why you can mix and match Perl and WebChat. Handy huh? 

See L<webchatpp> for more details on the syntax.

=head1 USAGE

You never actually use C<Inline::WebChat> directly. It is just a support module for using C<Inline.pm> with WebChat. So the usage is always:

    use Inline WebChat => ...;

or

    bind Inline WebChat => ...;


=head1 USING MORE THAN ONE SUBROUTINE / USING THE MODULE WITH Test::More

Apparently there are problems using Inline::Webchat with more than one subroutine. 

This is a work around from Richard Clamp (bless his cotton socks) which isn't perfect but, as he so delightfully puts it "I imagine getting it to work correctly requires the ability to parse webchat augmented perl.  The thought of that hurts my brain."

If anybody can figure out a better way to do it then please tell me. I need to do more testing on this.

#!perl -w                                                                                                                                                    use strict;

use Test::More tests => 2;
use TestConfig;

use Inline 'WebChat' => <<SCRIPT;

sub is_up {
    GET $TestConfig::site
    EXPECT OK
    return 1

}

SCRIPT

is(is_up(), 1, "site is up");

use Inline 'WebChat' => <<SCRIPT;

sub will_404 {
    GET $TestConfig::site/four_oh_four
    EXPECT ERROR
    return 1;

}                                                                                                                                                            


SCRIPT

is(will_404, 1, "404s $TestConfig::site/four_oh_four");

__END__          

=head1 BUGS AND DEFICIENCIES

=over 4

=item 

o None so far but I haven't tested it very much. Go! Hack! Break! Let me know what's wrong.

=item 

o Could do with some more examples

=item 

o I'm not happy with the whole WebChat design in general - I mean, I had to patch it to get it working with  his in the first place. Hmm, maybe when I have more time.

=back

=head1 SEE ALSO

For general information about Inline see L<Inline>.

For more information about C<WebChat> see L<webchatpp>, L<WWW::Chat> and L<WWW::Chat::Processor>

For information on supported languages and platforms see L<Inline-Support>.

For information on writing your own Inline Language Support Module, see L<Inline-API>.

Inline's mailing list is inline@perl.org

To subscribe, send email to inline-subscribe@perl.org


=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright (c) 2001. Simon Wistow. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
