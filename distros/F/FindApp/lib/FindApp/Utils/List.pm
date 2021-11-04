package FindApp::Utils::List;

use v5.10;
use strict;
use warnings;

use FindApp::Utils::Carp;
use FindApp::Utils::Assert  qw( :all );
use FindApp::Utils::Syntax  qw( function );

#################################################################

sub alldir_map           (  &    ) ;
sub colonize             (  @    ) ;
sub commify_and                    ;
sub commify_nor                    ;
sub commify_or                     ;
sub firsts_not_in_second ( \@ \@ ) ;
sub somedir_map          (  &@   ) ;
sub subdir_map           (  &    ) ;
sub uniq                           ;
sub uniq_files                     ;

#################################################################

use Exporter     qw(import);
our $VERSION = v1.0;
our @EXPORT_OK = (
    <commify_{and,or,nor}>,
    qw(
        alldir_map
        BLM
        colonize
        firsts_not_in_second
        somedir_map
        subdir_map
        uniq
        uniq_files
    ),
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#################################################################

sub BLM() { return qw(bin lib man); }

sub colonize(@) { join(":", @_) }

sub uniq {
    my %seen;
    return grep { !$seen{$_}++ } grep {defined} @_;
}

sub uniq_files {
    my @input = @_; 
    my %seen;
    my @output;
    for my $file (@input) {
        next if $seen{$file}++;
        next unless stat $file;
        my($dev,$ino) = stat _;
        next if $seen{$dev,$ino}++;
        push @output, $file;
    }   
    return @output;
}

# Yes, this isn't working right for undef. That shouldn't be a path element
# anyway but there are bugs in Env.pm this is working around.
sub firsts_not_in_second(\@ \@) {
    good_args(@_ == 2);
    my($aref, $bref) = @_;

    # worst case
    local $SIG{__WARN__} = sub {};

    my %seen = map { $_ => 1 }  grep {defined} @$bref;
    return grep { ! $seen{$_} } grep {defined} @$aref;
}

sub somedir_map(&@) {
    good_args(@_ > 0);
    my $code = shift;
    return map { &$code } @_;
}

sub subdir_map(&) {
    good_args(@_ == 1);
    my $code = shift;
    return somedir_map(\&$code, BLM);
}

sub alldir_map(&) {
    good_args(@_ == 1);
    my $code = shift;
    return somedir_map(\&$code, root => BLM);
}

#################################################################

for my $CONJ (qw(and or nor)) {
    function "commify_$CONJ" => sub {
        my $comma = "@_" =~ /,/ ? ";" : ",";
        (@_ == 0) ? ""                                      :
        (@_ == 1) ? $_[0]                                   :
        (@_ == 2) ? join(" $CONJ " => @_)                   :
                    join("$comma " => @_[0 .. ($#_-1)], 
                                        "$CONJ $_[-1]"  );
    };
}

1;

=encoding utf8

=head1 NAME

FindApp::Utils::List - FIXME

=head1 SYNOPSIS

 use FindApp::Utils::List;

=head1 DESCRIPTION

=head2 Exports

=over

=item alldir_map

=item BLM

=item colonize

=item commify_and

=item commify_nor

=item commify_or

=item firsts_not_in_second

=item somedir_map

=item subdir_map

=item uniq

=item uniq_files

=back

=head1 EXAMPLES

=head1 ENVIRONMENT

=head1 SEE ALSO

=over

=item L<FindApp>

=back

=head1 CAVEATS AND PROVISOS

=head1 BUGS AND LIMITATIONS

=head1 HISTORY

=head1 AUTHOR

Tom Christiansen << <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

