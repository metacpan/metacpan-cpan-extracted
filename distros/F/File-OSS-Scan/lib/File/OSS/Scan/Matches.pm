=head1 NAME

File::OSS::Scan::Matches - store scan result about file matches

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use File::OSS::Scan::Matches;

    File::OSS::Scan::Matches->init();

    File::OSS::Scan::Matches->add(
                        {
                            'name'  => $h_file->{'name'},
                            'path'  => $h_file->{'path'},
                            'size'  => $h_file->{'size'},
                            'mtime' => $h_file->{'mtime'},
                        },
                        $function_name,
                        $certainty_level,
                        join(' ', @$args),
                        $message
                    );

    my $matches = File::OSS::Scan::Matches->get_matches();

=head1 DESCRIPTION

This is an internal module used by L<File::OSS::Scan> to store scan results,
and should not be called directly.

=head1 SEE ALSO

=over 4

=item * L<File::OSS::Scan>

=back

=head1 AUTHOR

Harry Wang <harry.wang@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Harry Wang.

This is free software, licensed under:

    Artistic License 1.0

=cut

package File::OSS::Scan::Matches;

use strict;
use warnings FATAL => 'all';

use Fatal qw( open close );
use Carp;
use English qw( -no_match_vars );
use Data::Dumper; # for debug
use JSON;

use File::OSS::Scan::Constant qw(:all);

our $VERSION = '0.04';

# global var ...
our $matches = undef;

sub init {
    my $self = shift;
    undef $matches;

    return SUCCESS;
}

sub add {
    my $self = shift;

    my ( $h_file, $func, $cert, $args, $msg )
        = @_ or return SUCCESS;

    my $key = $h_file->{'path'};
    my $new_h_file = {
        'name'  => $h_file->{'name'},
        'size'  => $h_file->{'size'},
        'mtime' => $h_file->{'mtime'},
    };

    $matches->{$key} = $new_h_file
        if ( not exists $matches->{$key} );

    push @{$matches->{$key}->{'matches'}}, {
        'func'  => $func,
        'cert'  => $cert,
        'args'  => $args,
        'msg'   => $msg,
    };

    return SUCCESS;
}

sub get_matches {
    my $var = $_[0] . "::matches";
    my $fmt = $_[1];

    no strict 'refs';

    if ( not defined $fmt ) {
        return $$var;
    }
    else {
        my $func = __PACKAGE__ . "::__" . $fmt;

        if ( defined(&$func) ) {
            return &$func($$var);
        }
        else {
            croak "can't find function $func in " . __PACKAGE__;
        }
    }
}

sub  __txt {
    my $result = shift;
    my $ret = undef;

    if ( defined $result ) {
        $ret = '';
        my $num = 1;

        foreach my $path ( sort keys %$result ) {
            my ( $matches, $mtime, $name, $size )
                = @{$result->{$path}}{
                    qw/matches mtime name size/
                  };

            my $mtime_stamp = localtime($mtime);
            $ret .= sprintf( "%-16s %-50s\n", "Matches \#\($num\):", $path );
            $ret .= sprintf( "%-16s %-20s %-10s %-20s\n", "",
                    "name:$name", "size:$size", "mtime:$mtime_stamp" );

            if ( defined $matches ) {
                my $num_of_match = 1;

                foreach my $match ( @$matches ) {
                    $ret .= sprintf("%-20s %-5s %-5s %-20s %-20s\n",
                        "", "\<$num_of_match\>\.", $match->{'cert'} . '%',
                        $match->{'func'}, $match->{'args'} );

                    $ret .= " " x 24 . "$match->{'msg'}\n";
                    $num_of_match++;
                }
            }

            $num++;
        }
    }

    return $ret;
}

# mainly for the body content of mail
sub __html {
    my $result = shift;
    my $ret = undef;

    if ( defined $result ) {
        my $num = 1;
        $ret = '';

        foreach my $path ( sort keys %$result ) {
            my ( $matches, $mtime, $name, $size )
                = @{$result->{$path}}{
                    qw/matches mtime name size/
                  };

            my $mtime_stamp = localtime($mtime);
            $ret .= "<table id='scan_result_table' cellspacing='0'>\n";
            $ret .= "<tr><th width='700px'>(#$num) $path</th><th width='50px'>$size</th><th width='250px'>$mtime_stamp</th></tr>\n";

            if ( defined $matches ) {
                my $num_of_match = 1;

                foreach my $match ( @$matches ) {
                    $ret .= "<tr><table>\n" .
                            "<tr><td width='50px'>\<$num_of_match\></td>\n" .
                                "<td width='50px'>$match->{'cert'}\%</td>\n" .
                                "<td width='200px'>$match->{'func'}</td>\n" .
                                "<td width='300px'>$match->{'args'}</td>\n" .
                                "<td width='400px'>$match->{'msg'}</td>\n" .
                            "</tr></table></tr>\n";

                    $num_of_match++;
                }
            }

            $num++;
        }

        $ret .= "</table>\n";

        my $css = join(q(), <DATA>);
        $ret = $css . "\n" . $ret;
    }

    return $ret;
}

sub __json {
    my $result = shift;
    my $ret = undef;

    $ret = JSON::to_json( $result, { pretty => 1 } )
    if ( defined $result );

    return $ret;
}



1;


__DATA__
<style type="text/css">
/* CSS Document */

body {
font: normal 11px auto Verdana;
color: #4f6b72;
background: #E6EAE9;
}

#scan_result_table {
width: 1000px;
padding: 0;
margin: 0;
}

th {
font: bold 11px Verdana;
color: #4f6b72;
border-right: 1px solid #C1DAD7;
border-bottom: 1px solid #C1DAD7;
border-top: 1px solid #C1DAD7;
letter-spacing: 2px;
text-align: left;
background: #CAE8EA   no-repeat;
}

td {
border-right: 1px solid #C1DAD7;
border-bottom: 1px solid #C1DAD7;
background: #fff;
font-size:11px;
padding: 6px 6px 6px 12px;
color: #4f6b72;
}

/*---------for IE 5.x bug*/
html>body td{ font-size:11px;}
body,td,th {
font-family: Verdana;
font-size: 12px;
}
</style>
