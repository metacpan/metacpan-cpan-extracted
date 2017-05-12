=head1 NAME

Test::Util - common code for testing

=head1 DESCRIPTION

=over

=cut

package Test::Util;

use strict;
use warnings;

=item * my $config_hashref = Test::Util::getconfig( $env );

Returns a hashref containing config for C<$env>, which it will expect to find in a file defined by C<$ENV{I<$env>CONFIG>. Returns undef if there are any problems (no such environment variable, no such file, etc.)

=cut

sub getconfig {
    my $env = shift;
    my %config;
    my $section;

    my $file = $ENV{$env . "CONFIG"};

    if ( $file ) {
        open( my $FILE, "<$file" ) or return;

        while( my $line = <$FILE> ) {
            if ( $line =~ /^\[(\w+)\]$/ ) {
                $section = $1;
                next;
            }

            if ( $section eq "secret" ) {
                my ( $key, $value ) = split( /\s*=\s*/, $line, 2 );
                next unless $key;
                next unless $value;
                $key =~ s/\s+//g;
                $value =~ s/^\s+//;
                $value =~ s/\s+$//;
                $config{$key} = $value;
            }
        }

        close( $FILE );
        return \%config;
    }

    return;
}

=item * my $file = Test::Util::getfile( $filename [, $context );

Return the contents of data/$context/$filename. If context is unset, it is determined from the caller's filename (e.g. PTSB.t results in a context of PTSB). Some transforms may be done on filename, e.g. trimming a query-string from the end. Returns undef if the file cannot be found.

=cut

sub getfile {
    my $file = shift;
    my $context = shift;
    my $content;

    $file =~ s@/$@/index.html@;

    # figure out which bank test is calling us and use that to find the files
    if ( !$context ) {
        ( $context ) = (caller)[1];
        $context =~ s@t/(.*)\.t$@$1@;
        $context =~ s@\.pm$@@;
    }

    $file =~ s@^\w+?://[^/]+@@;
    $file =~ s@^(.*/)*@data/$context/@;

    while ( 1 ) {
        ( my $fs_file = $file ) =~ s/\?/_/;
        print STDERR "#  looking for $fs_file\n" if $ENV{DEBUG};
        if ( open( my $CONTENT, '<', $fs_file )) {
            local $/ = undef;
            $content = <$CONTENT>;
            return $content;
        } else {
            if ( $file =~ s/\?.*$// ) {
                next;
            }
        }

        last;
    }

}

sub setup {
    my ( $MODULE_UNDER_TEST ) = (caller)[1] =~ m@/?(\w+)\.t$@;

    eval "use Test::MockBank::$MODULE_UNDER_TEST\n";

    $MODULE_UNDER_TEST;
}

=back

=cut

1;
