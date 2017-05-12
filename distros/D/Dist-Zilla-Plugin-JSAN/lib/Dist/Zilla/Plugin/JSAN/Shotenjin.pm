package Dist::Zilla::Plugin::JSAN::Shotenjin;
BEGIN {
  $Dist::Zilla::Plugin::JSAN::Shotenjin::VERSION = '0.06';
}

# ABSTRACT: Run the "Shotenjin.Joosed" helper script for the javascript files with templates

use Moose;
use Moose::Autobox;

use Cwd;
use Path::Class;

use Shotenjin::Embedder;

with 'Dist::Zilla::Role::FileMunger';


has 'process_list' => (
    is  => 'rw'
);


sub munge_files {
    my ($self) = @_;
    
    for my $file ($self->zilla->files->flatten) {
        
        foreach my $entry (@{$self->process_list}) {
            
            if ($file->name =~ $entry->{ regex }) {
                
                $file->content(
                    Shotenjin::Embedder->process_string(
                        $file->content, 
                        $entry->{ keep_whitespace }, 
                        $entry->{ cwd_as_base } ? cwd() : file($file->name)->dir
                    )
                )
            }
            
        } 
    };
}


sub BUILDARGS {
    my ($class, @arg) = @_;
    
    my %copy            = ref $arg[0] ? %{$arg[0]} : @arg;

    my $zilla           = delete $copy{ zilla };
    my $plugin_name     = delete $copy{ plugin_name };

    my @params;

    foreach my $entry (keys(%copy)) {
        
        my %options = map { $_ => 1 } (split m/,/, $copy{ $entry });
        
        my $keep_whitespace = $options{ kw }        || $options{ keep_whitespace };
        my $cwd_as_base     = $options{ absolute }  || $options{ cwd_as_base };
        
        push @params, { regex => qr/$entry/, keep_whitespace => $keep_whitespace, cwd_as_base => $cwd_as_base };
    }
    

    return {
        zilla           => $zilla,
        plugin_name     => $plugin_name,
        process_list    => @params > 0 ? \@params : [ { regex => qr/^lib\b/, keep_whitespace => 0, cwd_as_base => 0 } ],
    }
}

no Moose;
__PACKAGE__->meta->make_immutable();


1;



__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::JSAN::Shotenjin - Run the "Shotenjin.Joosed" helper script for the javascript files with templates

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In your F<dist.ini>:

    [JSAN::Shotenjin]
    
    lib/Digest              = relative  // default, /*tjfile()tjfile*/ looks for files 
                                        // relative to the source JS file itself
    
    lib/Digest/MD5/Test     = absolute  // /*tjfile()tjfile*/ looks for files
                                        // relative to the current working directory
                                        // (distribution root)

=head1 DESCRIPTION

This plugin pre-process the source JavaScript files and extracts the template sources from the comments. Alternatively, 
it can extract the template content from the external file.

The plugin accepts the the list of regular expressions as configuration (each on own line). Expressions should be followed
with the equal sign and the relativity specification (either `relative` or `absolute` keyword).

Plugin will process only files matching one of the regular expressions passed.  

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

