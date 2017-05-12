package ETLp::Plugin::Serial::Perl;

use MooseX::Declare;

=head1 NAME

ETLp::Plugin::Iterative::PLSQL - Plugin for calling Oracle procedures

=head1 METHODS

=head2 type 

Registers the plugin type.

=head2 run

Executes the pipeline

=cut

class ETLp::Plugin::Serial::PLSQL extends ETLp::Plugin::Iterative::PLSQL {
    sub type {
        return 'plsql';
    }
}
