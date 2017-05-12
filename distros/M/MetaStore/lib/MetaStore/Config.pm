package MetaStore::Config;

=head1 NAME

MetaStore::Config - Configuration file class.

=head1 SYNOPSIS

    use MetaStore::Config;
    my $conf = new MetaStore::Config:: ( $opt{config} );
    my $value = $conf->general->{db_name};


=head1 DESCRIPTION

Configuration file class 

=head3 Format of  INI-FILE

Data is organized in sections. Each key/value pair is delimited with an
equal (=) sign. Sections are declared on their own lines enclosed in
'[' and ']':

  [BLOCK1]
  KEY1 ?=VALUE1
  KEY2 +=VALUE2


  [BLOCK2]
  KEY1=VALUE1
  KEY2=VALUE2

  #%INCLUDE file.inc%

B<?=>  - set value unless it defined before
B<+=>  - add value
B<=>   - set value to key
B<#%INCLUDE file.inc%> - include config ini file

=cut

use strict;
use warnings;
use WebDAO::Base;
use base 'WebDAO::Base';
use Text::ParseWords 'parse_line';
use IO::File;
our $VERSION = '0.3';

__PACKAGE__->mk_attr( __conf=>undef, _path=>undef);


#method for convert 'file_name', \*FH, \$string, <IO::File> to hash

sub convert_ini2hash {
    my $data = shift;

    #if we got filename
    unless ( ref $data ) {
        my $fh  = new IO::File:: "< $data";
        my $res = &convert_ini2hash($fh);
        close $fh;
        return $res;
    }

    #We got file descriptor ?
    if ( ref $data
        and ( UNIVERSAL::isa( $data, 'IO::Handle' ) or ( ref $data ) eq 'GLOB' )
        or UNIVERSAL::isa( $data, 'Tie::Handle' ) )
    {

        #read all data from file descripto to scalar
        my $str;
        {
            local $/;
            $str = <$data>;
        }
        return &convert_ini2hash( \$str );
    }
    my %result   = ();
    my $line_num = 0;
    my $section  = 'default';

    #if in param ref to scalar
    foreach ( split /(?:\015{1,2}\012|\015|\012)/, $$data ) {
        my $line = $_;
        $line_num++;

        # skipping comments and empty lines:

        $line =~ /^\s*(\n|\#|;)/ and next;
        $line =~ /\S/ or next;

        chomp $line;

        $line =~ s/^\s+//g;
        $line =~ s/\s+$//g;

        # parsing the block name:
        $line =~ /^\s*\[\s*([^\]]+)\s*\]$/ and $section = lc($1), next;

        # parsing key/value pairs
        # process ?= and += features
        if ( $line =~ /^\s*([^=]*\w)\s*([\?\+]?=)\s*(.*)\s*$/ ) {
            my $key   = lc($1);
            my @value = parse_line( '\s*,\s*', 0, $3 );
            my $op    = $2;

            #add current key
            if ( $op =~ /\+=/ ) {
                push @{ $result{$section}->{$key} }, @value;
                next;
            }

            # skip if already defined key
            elsif ( $op =~ /\?=/ ) {
                next if defined $result{$section}->{$key};
            }

            # set current value to result hash
            $result{$section}->{$key} = \@value;
            next;
        }

        # if we came this far, the syntax couldn't be validated:
        warn "syntax error on line $line_num: '$line'";
        return {};
    }

    #strip values
    while ( my ( $sect_name, $sect_hash ) = each %result ) {
        while ( my ( $key, $val ) = each %$sect_hash ) {
            if ( scalar(@$val) < 2 ) {
                $result{$sect_name}->{$key} = shift @$val;
            }
        }
    }
    return \%result;
}

sub get_full_path_for {
    my $root_file = shift;

    #    my $file_to   = shift;
    my @req_path = @_;
    my $req_path = join "/", @req_path;
    return $req_path if $req_path =~ /^\//;
    my @ini_path = split( "/", $root_file );

    #strip file name
    pop @ini_path;
    my $path = join "/" => @ini_path, $req_path;

    return $path;
}

sub process_includes {
    my $file = shift;
    my $fh   = ( new IO::File:: "< $file" ) || die "$file: $!";
    my $str  = '';
    while ( defined( my $line = <$fh> ) ) {

        $str .=
            $line =~ /#%INCLUDE\s*(.*)\s*%/
          ? &process_includes( &get_full_path_for( $file, $1 ) )
          : $line;
    }
    close $fh;
    return $str;
}

sub new {
    my $class = shift;
    my $self  = {};
    my $stat;
    bless( $self, $class );
    return ( $stat = $self->_init(@_) ) ? $self : $stat;
}

sub _init {
    my $self      = shift;
    my $file_path = shift;

    #process inludes in in data
    my $inc = &process_includes($file_path);
    $self->__conf( &convert_ini2hash(\$inc) );
    $self->_path($file_path);
    return 1;
}

sub get_full_path {
    my $self     = shift;
    my @req_path = @_;
    my $req_path = join "/", @req_path;
    return $req_path if $req_path =~ /^\//;
    my @ini_path = split( "/", $self->_path );
    pop @ini_path;
    my $path = join "/" => @ini_path, $req_path;
    return $path;
}

sub AUTOLOAD {
    my $self = shift;
    return if $MetaStore::Config::AUTOLOAD =~ /::DESTROY$/;
    ( my $auto_sub ) = $MetaStore::Config::AUTOLOAD =~ /.*::(.*)/;
    return $self->__conf->{$auto_sub};
}
1;
__END__

=head1 SEE ALSO

MetaStore, README

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

