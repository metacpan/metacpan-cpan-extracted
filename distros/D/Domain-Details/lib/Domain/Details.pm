package Domain::Details;

# ABSTRACT: Domain class with DNS/SSL/WHOIS fields

use v5.36;
use autouse 'Carp' => qw( carp croak );
# use autouse 'Data::Dumper' => qw( Dumper );
use autouse 'Data::Printer' => qw( p );

use Object::Pad ':experimental(init_expr)';
use Syntax::Keyword::Match;
use Net::Domain::ExpireDate; # Function: expire_date
use Domain::PublicSuffix;    # Method: get_root_domain
use POSIX;                   # Functions: setlocale, LC_ALL
use Net::SSL::ExpireDate;
use Net::DNS;
use Geo::IP;
use Term::ANSIColor;

class Domain::Details {
  use experimental qw( try );
  # @formatter:off
  field $domain :param :reader;
  field $comment :accessor;
  field $expiration :reader { $self -> _expiration };
  field $ssl_expiration :reader { $self -> _ssl_expiration };
  # @formatter:on
  method _expiration ( $format //= '%B %d, %Y' ) {
    my $publicsuffix = Domain::PublicSuffix -> new;
    setlocale( LC_ALL , 'en_US.UTF-8' );
    return expire_date( $publicsuffix -> get_root_domain( $domain ) , $format ); # domain without the www. prefix
  }
  method _ssl_expiration ( $format //=  "%s %s, %s" ) {
    my $ssl = Net::SSL::ExpireDate -> new( https => $domain );
    try {
      return sprintf $format ,
        $ssl -> expire_date -> month_name ,
        $ssl -> expire_date -> day ,
        $ssl -> expire_date -> year;
    }
    catch($message) {
      return undef;
    }
  }

  # @formatter:off
  method print_ssl :common ( $domain ) {
  # @formatter:on
    my $ssl = Net::SSL::ExpireDate -> new( https => $domain );
    try {
      my %date = ( # Class: DateTime
        expire => $ssl -> expire_date ,
        issue  => $ssl -> begin_date
      );
      printf( colored( [ 'red' ] , "SSL Expiry: %s %s, %s\n" ) , $date{expire} -> month_name , $date{expire} -> day , $date{expire} -> year );
      printf( colored( [ 'green' ] , "SSL Issue: %s %s, %s\n" ) , $date{issue} -> month_name , $date{issue} -> day , $date{issue} -> year );
      say colored( [ 'bright_red' , 'bold' ] , 'EXPIRES IN 14 DAYS' )
        if defined $ssl -> is_expired( '14 days' );
    }
    catch($message) {
      warn "SSL: $message";
    }
  }

  # @formatter:off
  method print_dns :common ( $domain ) {
  # @formatter:on
    my $dns = Net::DNS::Resolver -> new;

    my $a = $dns -> query( $domain , 'A' ); # may return Net::DNS::RR::CNAME (w/ cname method)
    my @a = $a -> answer if defined $a;

    my $cname;

    my $mx = $dns -> query( $domain , 'MX' ); # class: Net::DNS::Packet
    my @mx = $mx -> answer if defined $mx;

    my $ns = $dns -> query( $domain , 'NS' );
    my @ns = $ns -> answer if defined $ns;

    my $ptr;

    my $txt = $dns -> query( $domain , 'TXT' );
    my @txt = $txt -> answer if defined $txt;

    my $soa = $dns -> query( $domain , 'SOA' );
    my @soa = $soa -> answer if defined $soa;

    my $answer;
    my %dns = (
      a     => [] ,
      cname => '' ,
      ptr   => [] ,
      mx    => [] ,
      ns    => [] ,
      txt   => [] ,
    ); # TODO: %dns_colors

    my $geo = Geo::IP -> open( '/usr/share/GeoIP/GeoIP.dat' );
    # Debian, perlbrew 5.36 fails to open for searching in /usr/local when Geo::IP is being installed with cpan
    # libgeo-ip-perl Debian package probably patches it
    # my $geo = Geo::IP->new(GEOIP_MEMORY_CACHE); # faster

    for my $record ( @a , @mx , @ns , @txt , @soa ) # Net::DNS::RR object list
    {
      match( $record -> type : eq )
      {
        case( 'A' )
        {
          $answer .= sprintf( "A:\t%s (%s)\n" , $record -> address , $geo -> country_code_by_addr( $record -> address ));
          push( $dns{a} -> @* , $record -> address );
          $ptr = $dns -> query( $record -> address , 'PTR' ); # Net::DNS::Packet
          if ( $ptr ) {
            my @ptr = $ptr -> answer; # [ Net::DNS:RR, ... ]
            $answer .= Term::ANSIColor::colored( [ 'bright_cyan' ] , sprintf( "P:\t%s (%s)\n" , $ptr[0] -> ptrdname , $geo -> country_code_by_name( $ptr[0] -> ptrdname )));
            # eq. rdatastr (undocumented)
            push( $dns{ptr} -> @* , $ptr[0] -> ptrdname );
          }
        }
        case( 'CNAME' )
        {
          # fetched by A, for instance
          $cname = Term::ANSIColor::colored( [ 'bright_magenta' ] , sprintf( "C:\t%s (%s)\n" , $record -> cname , $geo -> country_code_by_name( $record -> cname )));
          # 4 - 5 times (seemingly by A)
          $dns{cname} = $record -> cname;
        }
        case( 'MX' )
        {
          $answer .= Term::ANSIColor::colored( [ 'bright_yellow' ] , sprintf( "M:\t%s (%s)\n" , $record -> exchange , $geo -> country_code_by_name( $record -> exchange )));
          push( $dns{mx} -> @* , $record -> exchange );
        }
        case( 'NS' )
        {
          $answer .= Term::ANSIColor::colored( [ 'bright_green' ] , sprintf( "N:\t%s (%s)\n" , $record -> nsdname , $geo -> country_code_by_name( $record -> nsdname )));
          push $dns{ns} -> @* , $record -> nsdname;
        }
        case( 'TXT' )
        {
          $answer .= Term::ANSIColor::colored( [ 'bright_white' ] , sprintf( "T:\t%s\n" , $record -> txtdata ));
          push $dns{txt} -> @* , $record -> txtdata;
        }
        case( 'SOA' )
        { # fetched by A, for instance
          $answer .= Term::ANSIColor::colored(
            [ 'bright_red' ] ,
            sprintf( "S:\t%s %s\n" ,
              $record -> mname ,
              $record -> rname
            )
          );
        }
      }

    }

    # say Data::Dumper::Dumper %dns;

    $answer = $answer . $cname if defined $cname;
    # return $answer;
    say $answer;
  }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Domain::Details - Domain class with DNS/SSL/WHOIS fields

=head1 VERSION

version 1.230280

=head1 AUTHOR

Elvin Aslanov <rwp.primary@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Elvin Aslanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
