
package IOC::Config::XML;

use strict;
use warnings;

our $VERSION = '0.03';

use IOC::Exceptions;
use IOC::Config::XML::SAX::Handler;

use XML::SAX::ParserFactory;

sub new {
    my ($_class) = @_;
    my $class = ref($_class) || $_class;
    my $config = {
        _config => {}
    };
    bless($config, $class);
    return $config;
}

sub read {
    my ($self, $source) = @_;
    (defined($source) && $source) 
        || throw IOC::InsufficientArguments "You must provide something to read";
    my $handler = IOC::Config::XML::SAX::Handler->new();
    my $p = XML::SAX::ParserFactory->parser(Handler => $handler);
    if ($source =~ /\.xml$/) {
        $p->parse_uri($source);
    }
    else {
        $p->parse_string($source);
    }
}

1;

__END__

=head1 NAME

IOC::Config::XML - An XML Config reader for IOC

=head1 SYNOPSIS

  use IOC::Config::XML;
  
  my $conf_reader = IOC::Config::XML->new();
  $conf_reader->read('my_ioc_conf.xml');
  
  # now the IOC::Registry singleton is all configured

=head1 DESCRIPTION

This is the second version of an XML configuration module for IOC. The first version used L<XML::Simple>, which is a great module, but not really the best fit for this. I have now ported this over to use L<XML::SAX>, which is much more flexible solution (not to mention a really nice way to interact with XML). I consider this module to be late-BETA quality (it is currently in production and working without issue for a month now).

=head1 SAMPLE XML CONF

    E<lt>RegistryE<gt>
        E<lt>Container name='Application'E<gt>
            E<lt>Container name='Database'E<gt>      
                E<lt>Service name='dsn'      type='Literal'E<gt>dbi:Mock:E<lt>/ServiceE<gt>            
                E<lt>Service name='username' type='Literal'E<gt>userE<lt>/ServiceE<gt>            
                E<lt>Service name='password' type='Literal'E<gt>****E<lt>/ServiceE<gt>                                    
                E<lt>Service name='connection' type='ConstructorInjection' prototype='true'E<gt>
                    E<lt>Class name='DBI' constructor='connect' /E<gt>
                    E<lt>Parameter type='component'E<gt>dsnE<lt>/ParameterE<gt>                
                    E<lt>Parameter type='component'E<gt>usernameE<lt>/ParameterE<gt>
                    E<lt>Parameter type='component'E<gt>passwordE<lt>/ParameterE<gt>                            
                E<lt>/ServiceE<gt>
            E<lt>/ContainerE<gt>     
            E<lt>Service name='logger_table' type='Literal'E<gt>tbl_logE<lt>/ServiceE<gt>               
            E<lt>Service name='logger' type='SetterInjection'E<gt>
                E<lt>Class name='My::DB::Logger' constructor='new' /E<gt>
                E<lt>Setter name='setDBIConnection'E<gt>/Database/connectionE<lt>/SetterE<gt>
                E<lt>Setter name='setDBTableName'E<gt>logger_tableE<lt>/SetterE<gt>            
            E<lt>/ServiceE<gt> 
            E<lt>Service name='template_factory' type='ConstructorInjection'E<gt>
                E<lt>Class name='My::Template::Factory' constructor='new' /E<gt>
                E<lt>Parameter type='perl'E<gt>[ path =E<gt> 'test' ]E<lt>/ParameterE<gt>                          
            E<lt>/ServiceE<gt> 
            E<lt>Service name='app'E<gt>
                E<lt>![CDATA[
                    my $c = shift;
                    my $app = My::Application-E<gt>new();
                    $app-E<gt>setLogger($c-E<gt>get('logger'));
                    return $app;
                ]]E<gt>
            E<lt>/ServiceE<gt>           
        E<lt>/ContainerE<gt>
    E<lt>/RegistryE<gt>

=head1 METHODS

=over 4

=item B<new>

Create a new XML::Config::XML object to read a configuration and intialize the L<IOC::Registry>.

=item B<read ($source)>

Given an XML C<$source> file or string, this will read the XML in it and intialize the L<IOC::Registry> singleton.

=back

=head1 TO DO

=over 4

=item Handle Includes

I thought this will be implemented when I moved to XML::SAX, but it didn't. I am thinking I will try to handle this on my own instead of trying to use XML tricks

=item Handle Aliasing

This is a minor feature of IOC::Registry, but I want to support it in here eventually. It shouldn't be a problem really, just don't currently have a need to get it in place.

=item Handle IOC::Proxy objects

It would be nice if you could configure IOC::Proxy objects through XML as well.

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, see the CODE COVERAGE section of L<IOC> for more information.

=head1 SEE ALSO

=over 4

=item L<XML::SAX>

=item L<XML::SAX::ParserFactory>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

