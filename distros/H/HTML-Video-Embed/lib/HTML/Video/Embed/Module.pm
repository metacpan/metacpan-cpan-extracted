package HTML::Video::Embed::Module;
use Moo::Role;

requires 'domain_reg';
requires 'process';

sub ssl {
    0;
}

1;
