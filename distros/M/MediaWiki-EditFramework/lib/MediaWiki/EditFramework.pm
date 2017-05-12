=head1 NAME

MediaWiki::EditFramework - a framework for editing MediaWiki pages.

=head1 SYNOPSIS

 use MediaWiki::EditFramework;

 my $wiki = MediaWiki::EditFramework->new('example.com', 'wiki');
 my $page = $wiki->get_page('Main_Page');
 my $text = $page->get_text;
 $text =~ s/old thing/new update/g;
 $page->edit($text, 'update page');

=head2 DESCRIPTION

This is a higher level framework for editing MediaWiki pages.  It depends on
another module for lower level API access, and doesn't provide functionality
unrelated to editing.  By using a higher-level abstraction layer in scripts,
it becomes simpler to change out backend modules as needed.

This is the framework that I've been using for the past few years to run an
archiving bot.  The main features that it has over lower-level frameworks
are:

=over

=item *

Pages are represented as objects.  

This allows the page to store additional information, such as the last
updated timestamp when they were retrieved.  The timestamp is then passed
back to the server when the page is edited, to allow it to properly detect
edit conflicts.

=item *

The module supports specified a write_prefix, which is appended to pages
titles when editing a page.  

This makes it easier to create a test mode for a bot script.  By specifying
the write prefix in your own user space, the bot will retrieve the normal
pages, but the modifications will be written to user space so you can review
them without impacting others.

=back

=cut

package MediaWiki::EditFramework;

use strict;
use warnings;

use Carp;
use MediaWiki::API;
use Data::Dumper;
use MediaWiki::EditFramework::Page;
use strict;

our $VERSION = '0.02';
our $ABSTRACT = 'framework for editing MediaWiki pages';

=head2 CONSTRUCTOR

=over

=item B<new>(I<SITE>,I<PATH>)

Create a new instance pointing to the specified I<SITE> and I<PATH> (default
I<w>).  The underling API object points to http://I<SITE>/I<PATH>/api.php.

=back

=head2 METHODS

=over

=cut

sub new ($;$$) {
    my ($class,$site,$path)=@_;
    my $mw = MediaWiki::API->new();
    if (defined $site) {
	$path = 'w' unless defined $path;
	$mw->{config}->{api_url} = "http://$site/$path/api.php";
    }
    #$mw->{ua}->cookie_jar({file=>"$ENV{HOME}/.cookies.txt", autosave=>1});
    bless {0=>$mw, write_prefix=>''}, $class;
}

=item B<cookie_jar>(I<FILE>) 

Passes I<FILE> to L<LWP::UserAgent>'s I<cookie_jar> method, to store cookies
for a persistent login.

=cut

sub cookie_jar( $$ ) {
    #temporary method for persistent login.
    my $self = shift;
    my $file = shift;
    $self->{0}{ua}->cookie_jar($file, autosave=>1);
}

=item B<login>(I<USER>,I<PASS>)

Log in the specified I<USER>.

=cut

sub login ($$$) {
    my ($self,$user,$pass) = @_;
    my $mw = $self->{0};

    my $state = $mw->api({ action=>'query', meta=>'userinfo', });
    
    if (
	 ! exists $state->{query}{userinfo}{anon}
	and
	$state->{query}{userinfo}{name} eq $user
	){ 
	warn "already logged in as $user";
    } else {
	$mw->login( { lgname => $user, lgpassword => $pass } )
	    or confess $mw->{error}->{code} . ': ' . 
	    Dumper($mw->{error}->{details});
    }
}


=item B<get_page>(I<TITLE>)

Get the wiki page with the specified I<TITLE>.  Returns an instance of
L<MediaWiki::EditFramework::Page>, which has methods to get/edit the page text.

=cut

sub get_page( $$ ) {
    MediaWiki::EditFramework::Page->new(@_);
};

=item B<create_page>(I<TITLE>)

Get the wiki page with the specified I<TITLE>; then croak if it already
exists.

=cut

sub create_page( $$ ) {
    my $page = MediaWiki::EditFramework::Page->new(@_);
    croak "$_[1]: exists" if $page->exists;
    return $page;
};

=item B<write_prefix>(I<PREFIX>)

When writing pages, prepend the specified I<PREFIX> to the page title.

This makes it easier to create a test mode for a bot script.  By specifying
the write prefix in your own user space, the bot will retrieve the normal
pages, but the modifications will be written to user space so you can review
them without impacting others.

=cut

sub write_prefix {
    my $self = shift;
    my $prefix = shift;
    $self->{write_prefix} = $prefix;
}

=back

=head1 SEE ALSO

L<MediaWiki::API>

=head1 COPYRIGHT

Copyright (C) 2012 by Steve Sanbeg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
