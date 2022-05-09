package File::Rename;

use strict;
BEGIN { eval { require warnings; warnings->import } }

our @EXPORT_OK = qw( rename );
our $VERSION = '1.31';

sub import {
    require Exporter;
    our @ISA = qw(Exporter);
    my( $pack ) = @_;
    $pack->export_to_level(1, @_);
    require File::Rename::Options;
}

sub rename_files {
    my $code = shift;
    my $options = shift;
    _default(\$options);

    my $sub = $code;
    if ( $options->{unicode_strings} ) {
        require File::Rename::Unicode;
        $sub = File::Rename::Unicode::code($code,
                            $options->{encoding});
    }
    my $errors;
    for (@_) {
        my $was = $_;
        if ( $options->{filename_only} ) {
            require File::Spec;
            my($vol, $dir, $file) = File::Spec->splitpath($_);
            $sub->() for ($file);
            $_ = File::Spec->catpath($vol, $dir, $file);
        }
        else {
            $sub->();
        }

        if( $was eq $_ ){ }     # ignore quietly
        elsif( -e $_ and not $options->{over_write} ) {
            if (/\s/ or $was =~ /\s/ ) {
                warn  "'$was' not renamed: '$_' already exists\n";
            }
            else {
                warn  "$was not renamed: $_ already exists\n";
            }
            $errors ++;
        }
        elsif( $options->{no_action} ) {
            print "rename($was, $_)\n";
        }
        elsif( CORE::rename($was,$_)) {
            print "$was renamed as $_\n" if $options->{verbose};
        }
        else {  warn  "Can't rename $was $_: $!\n"; $errors ++; }
    }
    return !$errors;
}

sub rename_list {
    my($code, $options, $fh, $file) = @_;
    _default(\$options);
    print "Reading filenames from ",
      ( defined $file ?                 $file
        : defined *{$fh}{SCALAR} and
          defined ${*{$fh}{SCALAR}} ?   ${*{$fh}{SCALAR}}
        :                               "file handle ($fh)"
      ),
      "\n" if $options->{verbose};
    my @file;
    {
        local $/ = "\0" if $options->{input_null};
        chop(@file = <$fh>);
    }
    rename_files $code, $options,  @file;
}

sub rename {
    my($argv, $code, $verbose) = @_;
    if( ref $code ) {
        if( 'HASH' eq ref $code ) {
            if(defined $verbose ) {
                require Carp;
                Carp::carp(<<CARP);
File::Rename::rename: third argument ($verbose) ignored
CARP
            }
            $verbose = $code;
            $code = delete $verbose->{_code};
            unless ( $code ) {
                require Carp;
                Carp::carp(<<CARP);
File::Rename::rename: no _code in $verbose
CARP
            }

        }
    }
    unless( ref $code ) {
        if( my $eval = eval <<CODE )
sub {
$code
}
CODE
        {
            $code = $eval;
        }
        else {
            my $error = $@;
            $error =~ s/\b(at\s+)\(eval\s+\d+\)\s/$1/g;
            $error =~ s/(\s+line\s+)(\d+)\b/$1 . ($2-1)/eg;
            $error =~ s/\.?\s*\z/, in:\n$code\n/;
            die $error;
        }
    }
    if( @$argv ) { rename_files $code, $verbose, @$argv }
    else { rename_list $code, $verbose, \*STDIN, 'STDIN' }
}

sub _default {
    my $ref = shift;
    return if ref $$ref;
    my $verbose = $$ref;
    $$ref = { verbose => $verbose }
}

1;

__END__

=head1 NAME

File::Rename - Perl extension for renaming multiple files

=head1 SYNOPSIS

  use File::Rename qw(rename);          # hide CORE::rename
  rename \@ARGV, sub { s/\.pl\z/.pm/ }, 1;

  use File::Rename;
  File::Rename::rename \@ARGV, '$_ = lc';

=head1 DESCRIPTION

=over 4

=item C<rename( FILES, CODE [, VERBOSE])>

rename FILES using CODE,
if FILES is empty read list of files from stdin

=item C<rename_files( CODE, VERBOSE, FILES)>

rename FILES using CODE

=item C<rename_list( CODE, VERBOSE, HANDLE [, FILENAME])>

rename a list of file read from HANDLE, using CODE

=back

=head2 OPTIONS

=over 8

=item FILES

List of files to be renamed,
for C<rename> must be an ARRAY reference

=item CODE

Subroutine to change file names,
for C<rename> can be a string,
otherwise it is a code reference

=item VERBOSE

Flag for printing names of files successfully renamed,
optional for C<rename>

=item HANDLE

Filehandle to read file names to be renames

=item FILENAME (Optional)

Name of file that HANDLE reads from

=back

=head2 HASH

Either CODE or VERBOSE can be a HASH of options.

If CODE is a HASH, VERBOSE is ignored 
and CODE is supplied by the B<_code> key.

Other options are 

=over 16

=item B<verbose>

As VERBOSE above, provided by B<-v>.

=item B<input_null>

Input separator \0 when reading file names from stdin.

=item B<no_action>

Print names of files to be renamed, but do not rename
(i.e. take no action), provided by B<-n>.

=item B<over_write>

Allow files to be over-written by the renaming, provided by B<-f>. 

=item B<filename_only>

Only apply renaming to the filename component of the path, 
provided by B<-d>.

=item B<show_help>

Print help, provided by B<-h>.

=item B<show_manual> 

Print manual page, provided by B<-m>.

=item B<show_version> 

Print version number, provided by B<-V>.

=item B<unicode_strings> 

Enable unicode_strings feature, provided by B<-u>.

=item B<encoding> 

Encoding for filenames, provided by B<-u>.

=back

=head2 EXPORT

None by default.

=head1 ENVIRONMENT

No environment variables are used.

=head1 SEE ALSO

mv(1), perl(1), rename(1)

=head1 AUTHOR

Robin Barker <RMBarker@cpan.org>

=head1 Acknowledgements

Based on code from Larry Wall.

Options B<-e>, B<-f>, B<-n> suggested
by more recent code written by Aristotle Pagaltzis.

=head1 DIAGNOSTICS

Errors from the code argument are not trapped.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004, 2005, 2006, 2011, 2018, 2021 by Robin Barker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

