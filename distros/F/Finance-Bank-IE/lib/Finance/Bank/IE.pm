=head1 NAME

Finance::Bank::IE - shared functions for the Finance::Bank::IE module tree

=head1 DESCRIPTION

This module implements shared functions for Finance::Bank::IE::*

=over

=cut

package Finance::Bank::IE;

use File::Path;
use WWW::Mechanize;
use HTTP::Status qw(:constants);
use Carp qw( confess );

use strict;
use warnings;

our $VERSION = "0.30";

# Class state. Each of these is keyed by the hash value of $self to
# provide individual class-level variables. Ideally I'd just hack the
# namespace of the subclass, though.
my %agent;
my %cached_config;

=item * $self->reset()

 Take necessary steps to reset the object to a pristine state, such as deleting cached configuration, etc.

=cut

sub reset {
    my $self = shift;

    $agent{$self} = undef;
    $cached_config{$self} = undef;;

    return 1;
}

=item * $self->_agent

 Return the WWW::Mechanize object currently in use, or create one if
 no such object exists.

=cut

sub _agent {
    my $self = shift;

    if ( !$agent{$self} ) {
        $agent{$self} = WWW::Mechanize->new( env_proxy => 1,
                                             autocheck => 0,
                                             keep_alive => 10 );
        if ( !$agent{$self}) {
            confess( "can't create agent" );
        }
        $agent{$self}->quiet( 0 );
    }

    $agent{$self};
}

=item * $self->cached_config( [config] )

  Get or set the cached config

=cut
sub cached_config {
    my ( $self, $config ) = @_;
    if ( defined( $config )) {
        $cached_config{$self} = $config;
    }

    return $cached_config{$self};
}

=item * $class = $self->_get_class()

 Return the bottom level class of $self

=cut
sub _get_class {
    my $self = shift;
    my $class = ref( $self );

    if ( !$class ) {
        $class = $self;
    }

    # clean it up
    my $basename = ( split /::/, $class )[-1];
    $basename =~ s/\.[^.]*$//;

    $basename;
}

=item * $scrubbed = $self->_scrub_page( $content )

 Scrub the supplied content for PII.

=cut
sub _scrub_page {
    my ( $self, $content ) = @_;

    return $content;
}

=item * $self->_save_page()

 Save the current page if $ENV{SAVEPAGES} is set. The pages are
 anonymised before saving so that they can be used as test pages
 without fear of divulging any information.

=cut

sub _save_page {
    my $self = shift;
    my @params = @_;
    return unless $ENV{SAVEPAGES};

    # get a filename from the agent
    my $res = $self->_agent()->response();
    my $filename = $res->request->uri();
    $filename =~ s@^.*/@@;
    if ( !$filename ) {
        $filename = "index.html";
    }

    if ( $self->_identify_page() ne 'UNKNOWN' ) {
        $filename = $self->_identify_page();
    }

    # embed the code if it's a failed page
    if ( !$res->is_success()) {
        $filename = $res->code() . "-$filename";
    }

    if ( @params ) {
        $filename .= '?' . join( '&', @params );
    }

    # Keep windows happy
    $filename =~ s/\?/_/g;

    my $path = 'data/savedpages/' . $self->_get_class();
    mkpath( [ $path ], 0, 0700 );
    $filename = "$path/$filename";

    $self->_dprintf( "writing data to $filename\n" );

    # we'd like to anonymize this content before saving it.
    my $content = $self->_agent()->content();
g
    $content = $self->_scrub_page( $content );

    my $error = 0;
    if ( open( my $FILEHANDLE, ">", $filename )) {
        binmode $FILEHANDLE, ':utf8';
        print $FILEHANDLE $content;
        close( $FILEHANDLE );
    } else {
        $error = $!;
        warn "Failed to create $filename: $!";
    }

    return $error;
}

=item * $self->_streq( $a, $b )

 Return $a eq $b; if either is undef, substitutes an empty string.

=cut

sub _streq {
    my ( $self, $a, $b ) = @_;

    $a = "" if !defined( $a );
    $b = "" if !defined( $b );

    return $a eq $b;
}

=item * $self->_rebuild_tag( $html_tokeparser_decomposed_tag )

 Return C<html_tokeparser_decomposed_tag> as a composed HTML tag.

=cut

sub _rebuild_tag {
    my $self = shift;
    my $data = shift;
    my $tag = $data->[1];
    if ( $data->[0] eq 'E' ) {
        $tag = "/$tag";
    }
    my $attr_values = $data->[2];
    my $attr_order = $data->[3];
    my @rebuild = "<$tag";
    for my $attr ( @{$attr_order} ) {
        next unless exists($attr_values->{$attr});
        my $attrstring = "$attr=";
        my $attrvalue = $attr_values->{$attr};
        $attrvalue =~ s@\\@\\\\@g;
        $attrvalue =~ s@"@\\"@g;
        $attrstring .= "\"$attrvalue\"";
        push @rebuild, $attrstring;
    }
    return join( ' ', @rebuild ) . ">";
}

=item * $self->_dprintf( ... )

 Print to STDERR using printf formatting if $ENV{DEBUG} is set.

=cut

sub _dprintf {
    my $self = shift;
    binmode( STDERR, ':utf8' );

    if ( $ENV{DEBUG}) {
        printf STDERR "[%s] ", ref( $self ) || $self || "DEBUG";
        printf STDERR @_ if $ENV{DEBUG};
    }
}

=item * $self->_pages()

 Return a hashref of URLs & sentinel text to allow each page to be requested or identified. Format of each entry is a hash, 'url' => 'http://...', 'sentinel' => 'sentinel text'. Sentinel text will be used as-is in a regular expression match on the page content.

=cut
sub _pages {
    my $self = shift;
    confess "_pages() not implemented for " . (ref($self) || $self);
}

=item * $self->_identify_page()

 Identify the current page among C<$self->_pages()> hashref. Returns C<UNKNOWN> if no match is found.

=cut
sub _identify_page {
    my $self = shift;
    my $content = shift || $self->_agent()->content();
    my $page;

    my $pages = $self->_pages();

    for my $pagekey ( keys %{$pages} ) {
        my $sentinel = $pages->{$pagekey}->{sentinel};
        if ( !$sentinel ) {
            confess( "sentinel unset for $pagekey" );
        }
        if ( $content =~ /$sentinel/s ) {
            $page = $pagekey;
            last;
        }
    }

    if ( !defined( $page )) {
        $page = "UNKNOWN";
    }

    return $page;
}

=item * $self->_get( url, [config] )

 Get the specified URL, dealing with login if necessary along the way.

=cut

sub _get {
    my $self = shift;
    my $url = shift;
    my $confref = shift;

    confess "No URL specified" unless $url;

    my $pages = $self->_pages();

    if ( $confref ) {
        $self->cached_config( $confref );
    }

    my $res;
    if ( $self->_agent()->find_link( url => $url )) {
        $self->_dprintf( " following $url\n" );
        $res = $self->_agent()->follow_link( url => $url );
    } else {
        $self->_dprintf( " getting $url\n" );
        $res = $self->_agent()->get( $url );
    }

    # if we get the login page then treat it as a 401
    my $loop = 0;
    my $expired = 0;
  NEXTPAGE:
    if ( $res->is_success ) {
        my $page = $self->_identify_page();
        if ( $page eq 'UNKNOWN' ) {
            $self->_dprintf( " Looking for URL '$url', got unknown page\n" );
            $page = "";
        } else {
            $self->_dprintf( " Looking for URL '$url', got '$page'\n" );
        }

        $self->_save_page();
        confess "unrecognised page" unless $page;

        if ( $page eq 'termsandconds' ) {
            die "Terms & Conditions page detected. Please log in manually to accept.";
        }

        if ( $page eq 'sitedown' ) {
            $res->code( HTTP_INTERNAL_SERVER_ERROR );
            die "Site appears to be offline for maintenance.";
        }

        if ( $page eq 'expired' or $page eq 'accessDenied' ) {
            if ( !$expired ) {
                $self->_dprintf( "  session expired, logging in again\n" );
                $res = $self->_agent()->get($self->_pages()->{login}->{url});
                $expired = 1;
                goto NEXTPAGE;
            } else {
                $self->_dprintf( " session expiry looping, bailing to avoid lockout\n" );
                $res->code( HTTP_INTERNAL_SERVER_ERROR )
            }
        } elsif ( $page eq 'login' ) {
            if ( $loop != 0 ) {
                $self->_dprintf( " login appears to have looped, bailing to avoid lockout\n" );
                $res->code( HTTP_UNAUTHORIZED );
            } else {
                # do the login
                $self->_dprintf( " login step 1\n" );
                $res = $self->_submit_first_login_page( $confref );
                $loop = 1;
                goto NEXTPAGE;
            }
        } elsif ( $page eq 'login2' ) {
            $self->_dprintf( " login 2 of 2\n" );
            if ( $loop ==2 ) {
                $self->_dprintf( " login appears to be stuck on page 2, bailing\n" );
                $res->code( HTTP_UNAUTHORIZED );
            } else {
                $res = $self->_submit_second_login_page( $confref );
                $loop = 2;
                goto NEXTPAGE;
            }
        } else {
            # just assume we're not yet on the page we're looking for
            if ( $self->_pages()->{$page}->{url} ne $url ) {
                $self->_dprintf( " now chasing URL '$url'\n" );
                $self->_save_page();
                $res = $self->_agent()->get( $url );
            }
        }
    }

    $self->_save_page();

    if ( $res->is_success ) {
        return $self->_agent()->content();
    } else {
        $self->_dprintf( "  page fetch failed with " . $res->code() . "\n" );
        return undef;
    }
}

=item * $self->_as_qif( $account_details_array_ref[, $type ] )

 Render C<$account_details_array_ref> as QIF. I<Very>
 limited. Optional C<$type> is the type of account.

 C<$account_details_array_ref> should be an arrayref of hashrefs, each
 containing the date, the payee, and the amount. Negative amounts
 indicate debits.

=cut

sub as_qif {
    my $self = shift;
    my $details_aref = shift;
    my $type = shift || "Bank";

    my $qif = "!Type:Bank\n";

    for my $details ( @{$details_aref} ) {
        $qif .= sprintf("D%s
P%s
T%0.02f
^
", $details->{date}, $details->{payee}, $details->{amount});
    }

    return $qif;
}

# starting the genericisation of this
sub check_balance {
    my $self = shift;
    my $confref = shift;
    $confref ||= $self->cached_config();

    my $res = $self->_get( $self->_pages()->{accounts}->{url}, $confref );
    return unless $res;

    return $self->_parse_account_balance_page();
}

=back

=cut

1;
