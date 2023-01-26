#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Brad Clawsie, 2023 -- brad.clawsie@gmail.com

package Lang::Go::Mod;
use warnings;
use strict;
use Carp qw(croak);
use English qw(-no_match_vars);
use Exporter qw(import);
use Path::Tiny qw(path);

# ABSTRACT: parse and model go.mod files

our $VERSION = '0.007';
our $AUTHORITY = 'cpan:bclawsie';

our @EXPORT_OK = qw(read_go_mod parse_go_mod _parse_retract);

sub read_go_mod {
    my $use_msg     = 'use: read_go_mod(go_mod_path)';
    my $go_mod_path = shift || croak $use_msg;

    my $go_mod_content = path($go_mod_path)->slurp_utf8 || croak "$ERRNO";

    return parse_go_mod($go_mod_content);
}

sub parse_go_mod {
    my $go_mod_content = shift || croak 'use: parse_go_mod(go_mod_content)';

    my $m = {};
    for my $k ( 'exclude', 'replace', 'require', 'retracts' ) {
        $m->{$k} = {};
    }
    my ( $excludes, $replaces, $requires, $retracts ) = ( 0, 0, 0, 0 );

    LINE: for my $line ( split /\n/x, $go_mod_content ) {
        next LINE if ( $line =~ /^\s*$/x );
        if ($excludes) {
            if ( $line =~ /^\s*[)]\s*$/x ) {
                $excludes = 0;
            }
            elsif ( $line =~ /\s*(\S+)\s+(\S+)/x ) {
                $m->{exclude}->{$1} = [] unless ( defined $m->{exclude}->{$1} );
                push @{ $m->{exclude}->{$1} }, $2;
            }
            else {
                croak "malformed exclude line $line";
            }
            next LINE;
        }
        if ($replaces) {
            if ( $line =~ /^\s*[)]\s*$/x ) {
                $replaces = 0;
            }
            elsif ( $line =~ /^\s*(\S+)\s+=>\s+(\S+)\s*$/x ) {
                croak "duplicate replace for $1"
                  if ( defined $m->{replace}->{$1} );
                $m->{replace}->{$1} = $2;
            }
            else {
                croak "malformed replace line $line";
            }
            next LINE;
        }
        if ($requires) {
            if ( $line =~ /^\s*[)]\s*$/x ) {
                $requires = 0;
            }
            elsif ( $line =~ /^\s*(\S+)\s+(\S+).*$/x ) {
                croak "duplicate require for $1"
                  if ( defined $m->{'require'}->{$1} );
                $m->{'require'}->{$1} = $2;
            }
            else {
                croak "malformed require line $line";
            }
            next LINE;
        }
        if ($retracts) {
            if ( $line =~ /^\s*[)]\s*$/x ) {
                $retracts = 0;
            }
            elsif ( $line =~ /^\s*(\S+)(.*)$/x ) {
                my $retract = _parse_retract( $1 . $2 );
                croak "unparseable retract content: $line"
                  unless ( defined($retract) );
                croak "duplicate retract for $retract"
                  if ( defined $m->{retract}->{$retract} );
                $m->{retract}->{$retract} = 1;
            }
            else {
                croak "malformed retract line $line";
            }
            next LINE;
        }

        # single-line directives
        if ( $line =~ /^module\s+(\S+)$/x ) {
            $m->{module} = $1;
        }
        elsif ( $line =~ /^go\s+(\S+)$/x ) {
            $m->{go} = $1;
        }

        # multi-line directive
        elsif ( $line =~ /^exclude\s+[(]\s*$/x ) {

         # toggle beginning of exclude block (and negate the other block checks)
            ( $excludes, $replaces, $requires, $retracts ) = ( 1, 0, 0, 0 );
        }
        elsif ( $line =~ /^replace\s+[(]\s*$/x ) {

         # toggle beginning of replace block (and negate the other block checks)
            ( $excludes, $replaces, $requires, $retracts ) = ( 0, 1, 0, 0 );
        }
        elsif ( $line =~ /^require\s+[(]\s*$/x ) {

         # toggle beginning of require block (and negate the other block checks)
            ( $excludes, $replaces, $requires, $retracts ) = ( 0, 0, 1, 0 );
        }
        elsif ( $line =~ /^retract\s+[(]\s*$/x ) {

         # toggle beginning of retract block (and negate the other block checks)
            ( $excludes, $replaces, $requires, $retracts ) = ( 0, 0, 0, 1 );
        }

        # single-line forms of multi-line directives
        elsif ( $line =~ /^exclude\s+(\S+)\s+(\S+)\s*$/x ) {

            # single exclude
            $m->{$1} = [] unless ( defined $m->{exclude}->{$1} );
            push @{ $m->{exclude}->{$1} }, $2;
        }
        elsif ( $line =~ /^replace\s+(\S+)\s+=>\s+(\S+)\s*$/x ) {

            # single replace
            croak "duplicate replace for $1"
              if ( defined $m->{replace}->{$1} );
            $m->{replace}->{$1} = $2;
        }
        elsif ( $line =~ /^require\s+(\S+)+\s+(\S+).*$/x ) {

            # single require
            croak "duplicate require for $1"
              if ( defined $m->{'require'}->{$1} );
            $m->{'require'}->{$1} = $2;
        }
        elsif ( $line =~ /^retract\s+(.+)/x ) {

            # single retract
            my $retract = _parse_retract($1);
            croak "unparseable retract content: $line"
              unless ( defined($retract) );
            croak "duplicate retract for $retract"
              if ( defined $m->{retract}->{$retract} );
            $m->{retract}->{$retract} = 1;
        }
        elsif ( $line =~ m{^\s*//.*$}mx ) {

            # comment - strip
            # (can also be part of a multi-line retract rationale)

        }
        else {
            croak "unparseable line content: $line";
        }
    }

    croak 'missing module line' unless ( defined $m->{module} );
    croak 'missing go line'     unless ( defined $m->{go} );

    return $m;
}

# 'private' sub to extract individual retract lines and strip off the rationale comments
# see: https://go.dev/ref/mod#go-mod-file-retract
#
# rationale comments are stripped out
#
# this sub should only see one line; if a retract rational had multiple lines, like:
# retract v1.0.0 // why
#                // oh why
#
# then the second comment line is caught by the comment match in the loop of parse_go_mod
sub _parse_retract {
    my $retract = shift || croak 'missing retract string';

    if ( $retract =~ /^\s*\[(.+?)\](.*)$/x ) {    # version-range
        my $range = $1;
        my $rest  = $2;

        # trim whitespace from range
        $range =~ s/\s+//gx;
        my @versions = split( /,/x, $range );
        my $count    = 0;
        for my $version (@versions) {
            return undef unless ( $version =~ /\S+/x );
            $count++;
        }
        return undef if ( $count != 2 );

        # if there is a comment, it must be properly formatted
        if ( $rest =~ /\S/x ) {
            return undef unless ( $rest =~ m{^\s+//}ox );
        }
        return '[' . $range . ']';
    }
    elsif ( $retract =~ /^\s*(\S+)(.*)$/x ) {    # single version
        my $version = $1;
        my $rest    = $2;

        # if there is a comment, it must be properly formatted
        if ( $rest =~ /\S/x ) {
            return undef unless ( $rest =~ m{^\s+//}ox );
        }
        return $version;
    }

    # unparseable retract string
    return undef;
}

1;

__END__

=head1 NAME

Lang::Go::Mod - parse and model go.mod files

=head1 SYNOPSIS

   # $ cat go.mod
   # module github.com/example/my-project
   # go 1.16
   # // comments
   # exclude (
   #    example.com/whatmodule v1.4.0
   # )
   # replace (
   #    github.com/example/my-project/pkg/app => ./pkg/app
   # )
   # require (
   #    golang.org/x/sys v0.0.0-20210510120138-977fb7262007 // indirect
   # )
   # retract (
   #    v1.0.0 // this version should not be used
   # )

   use Lang::Go::Mod qw(read_go_mod parse_go_mod);

   my $go_mod_path = '/path/to/go.mod';

   # read and parse the go.mod file
   #
   # all errors croak, so wrap this in your favorite variant of try/catch
   # to gracefully manage errors
   my $m = read_go_mod($go_mod_path);
   # use parse_go_mod to parse the go.mod content if it is already in a scalar
   # my $m = parse_go_mod($go_mod_file_content);

   print $m->{module}; # github.com/example/my-project
   print $m->{go}; # 1.16
   print $m->{exclude}->{'example.com/whatmodule'}; # [v1.4.0]
   print $m->{replace}->{'github.com/example/my-project/pkg/app'}; # ./pkg/app
   print $m->{'require'}->{'golang.org/x/sys'}; # v0.0.0-20210510120138-977fb7262007
   print $m->{retract}->{'v1.0.0'}; # 1

=head1 DESCRIPTION

This module creates a hash representation of a C<go.mod> file.
Both single line and multiline C<exclude>, C<replace>, C<require> and C<retract>
sections are supported. For a full reference of the C<go.mod> format, see

L<https://golang.org/doc/modules/gomod-ref>

=head1 EXPORTED METHODS

=head2 C<read_go_mod>

Given a full filepath for a C<go.mod> file, read it, parse it and
return the hash representation of the contents. All errors C<croak>.

=head2 C<parse_go_mod>

Given a scalar of the contents of a C<go.mod> file, parse it and
return the hash representation of the contents. All errors C<croak>.

=head1 LICENSE

Lang::Go::Mod is licensed under the same terms as Perl itself.

L<https://opensource.org/licenses/artistic-license-2.0>

=head1 CONTRIBUTORS

Ben Bullock (L<https://github.com/benkasminbullock>)
Brad Clawsie (L<https://b7j0c.org>)

=cut
