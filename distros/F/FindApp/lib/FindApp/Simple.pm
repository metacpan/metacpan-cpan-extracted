package FindApp::Simple;

use strict;
use warnings;

require FindApp;

use FindApp::Subs qw(:all);
use FindApp::Vars qw(:all);

use Exporter qw(import);

our %EXPORT_TAGS = (
    subs => [ @FindApp::Subs::EXPORT_OK ],
    vars => [ @FindApp::Vars::EXPORT_OK ],
);

our @EXPORT_OK = map { @$_ } @EXPORT_TAGS{<vars subs>};

$EXPORT_TAGS{all} = \@EXPORT_OK;
our @EXPORT = @EXPORT_OK;

1;

__END__

=head1 NAME

FindApp::Simple - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EXPORTS

=head1 SEE ALSO

=head1 AUTHOR

=head1 LICENCE AND COPYRIGHT
