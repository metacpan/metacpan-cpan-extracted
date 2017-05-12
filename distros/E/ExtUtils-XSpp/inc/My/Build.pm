package My::Build;

use strict;
use warnings;
use base qw(Module::Build);
use File::Spec ();

sub ACTION_code {
    my( $self ) = @_;

    # Generate the parser using yapp, unless Grammar.pm is read-only
    # (as it happens during a CPAN installation)
    my $grammar_module = File::Spec->catfile(qw(lib ExtUtils XSpp Grammar.pm));
    if( ( !-e $grammar_module || -w $grammar_module ) &&
        !$self->up_to_date( [ 'XSP.yp' ],
                            [ $grammar_module ] ) ) {
        $self->do_system( 'yapp', '-v', '-m', 'ExtUtils::XSpp::Grammar', '-s',
                          '-o', $grammar_module, 'XSP.yp' );

        # Replace the copy Parse::Yapp::Driver with a package in
        # our own namespace hierarchy
        open my $fh, '+<', $grammar_module
          or die "Could not open file '$grammar_module' for rw: $!";
        my @code = map {
          s{(?<!Module )Parse::Yapp::Driver}
           {ExtUtils::XSpp::Grammar::YappDriver}gx;
          $_
        } <$fh>;
        seek $fh, 0, 0;
        truncate $fh, 0;
        print $fh @code;
        close $fh or die "Updating grammar module failed: $!";
    }

    $self->SUPER::ACTION_code;
}

1;
