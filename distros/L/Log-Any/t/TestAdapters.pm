package TestAdapters;

use warnings;
use strict;

our @TEXT_LOG;
our @STRUCTURED_LOG;

package TestAdapters::Normal;
use base qw(Log::Any::Adapter::Base);
foreach my $method ( Log::Any->logging_methods() ) {
    no strict 'refs';
    *$method = sub { push @TestAdapters::TEXT_LOG, $_[1] };
}
foreach my $method ( Log::Any->detection_methods() ) {
    no strict 'refs';
    *$method = sub {1};
}

package TestAdapters::Structured;
use base qw(Log::Any::Adapter::Base);
use Storable 'dclone';

sub structured {
    my ( $self, $level, $category, @args ) = @_;

    my ( $messages, $data );
    for (@args) {
        if (ref) {
            push @$data, dclone($_);
        }
        else {
            push @$messages, $_;
        }
    }
    my $log_hash = { level => $level, category => $category };
    $log_hash->{messages} = $messages if $messages;
    $log_hash->{data}     = $data     if $data;
    push @TestAdapters::STRUCTURED_LOG, $log_hash;
}

foreach my $method ( Log::Any->detection_methods() ) {
    no strict 'refs';
    *$method = sub {1};
}

1;
