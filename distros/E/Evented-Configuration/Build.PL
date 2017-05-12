#!/usr/bin/perl
use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass(
    class => 'Evented::Configuration::Builder',
    code => q{
        sub ACTION_distmeta {
            my $self = shift;
            if (eval { require Pod::Markdown; 1 }) {

                $self->log_info("Creating README.md using Pod::Markdown\n");
                open my $fh, '>', 'README.md' or return $self->SUPER::ACTION_distmeta(@_);

                my $p = Pod::Markdown->new;
                my $markdown;
                $p->output_string(\$markdown);
                $p->parse_file('lib/Evented/Configuration.pm') or return $self->SUPER::ACTION_distmeta(@_);

                my (@lines, $in_block);
                foreach my $line (split "\n", $markdown) {

                    # indented code.
                    if (substr($line, 0, 4) eq '    ') {
                        my $code = substr($line, 4, length($line) - 4);
                        if ($in_block) {
                            push @lines, $code;
                            next;
                        }

                        push @lines, '````perl', $code;
                        $in_block = 1;
                        next;
                    }

                    # not indented.
                    if ($in_block) {
                        push @lines, '```', $line;
                        $in_block = 0;
                        next;
                    }

                    push @lines, $line;
                }

                print $fh $_, "\n" foreach @lines;
                close $fh;
                $self->_add_to_manifest('MANIFEST', 'README.md');
            }
            else {
                $self->log_warn("Cannot create README.md; Pod::Markdown unavailable\n");
            }
            return $self->SUPER::ACTION_distmeta(@_);
        }
    }
);

my $build = $class->new(
    module_name         => 'Evented::Configuration',
    dist_author         => 'Mitchell Cooper <cooper@cpan.org>',
    dist_abstract       => 'an evented configuration file in a unique and clean format',
    requires            => {
        'perl'              => '5.010',
        'Evented::Object'   => '5.55'
    },
    configure_requires  => {
        'Module::Build'     => '0.42'
    },
    recommends          => {},
    build_requires      => {},
    license             => 'bsd',
    create_makefile_pl  => 'traditional',
    dynamic_config      => 0,
    meta_merge          => {
        resources => {
            repository => 'https://github.com/cooper/evented-configuration'
        }
    },
);

$build->create_build_script;
