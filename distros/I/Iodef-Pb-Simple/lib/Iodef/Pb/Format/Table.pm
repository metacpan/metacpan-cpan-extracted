package Iodef::Pb::Format::Table;
use base 'Iodef::Pb::Format';

use strict;
use warnings;

use Text::Table;
use Regexp::Common qw/net/;

my $addr_regex = qr/$RE{'net'}{'IPv4'}|https?|ftp|[a-z0-9._]+\.[a-z]{2,6}/;

sub write_out {
    my $self = shift;
    my $args = shift;
    
    my $array = $self->to_keypair($args);
    
    # we will look for each variable in the [query] section
    # if it isnt there, we will check the [client] section.
    # if it's not there either, we'll use the default

    my $config = $args->{'config'};

    my @config_search_path      = ( 'claoverride', $args->{'query'}, 'client' );
    
    my $cfg_fields              = $args->{'fields'}             || $self->SUPER::confor($config, \@config_search_path, 'fields',             undef);
    my $cfg_display             = $args->{'display'}            || $self->SUPER::confor($config, \@config_search_path, 'display',            undef);
    my $cfg_compress_address    = $args->{'compress_address'}   || $self->SUPER::confor($config, \@config_search_path, 'compress_address',   undef);
    my $cfg_description         = $args->{'description'}        || $self->SUPER::confor($config, \@config_search_path, 'description',        undef);
    my $cfg_table_nowarning     = $args->{'table_nowarning'}    || $self->SUPER::confor($config, \@config_search_path, 'table_nowarning',    undef);
    my $cfg_table_showmeta      = $args->{'table_showmeta'}     || $self->SUPER::confor($config, \@config_search_path, 'table_showmeta',     undef);
  
    my @cols;
    push(@cols,'id') if($args->{'table_uuid'});
    push(@cols,'relatedid') if($args->{'table_relatedid'});
    push(@cols,(
        'restriction',
        'guid',
        'assessment',
        'description',
        'confidence',
        'detecttime',
        'reporttime',
    ));
   
    # override
    if($cfg_fields){
        @cols = @$cfg_fields;
    }

    my %c;
    unless($cfg_fields){
        foreach my $e (@$array){
            $c{'address'}       = 1 if($e->{'address'});
            $c{'hash'}          = 1 if($e->{'hash'});
            $c{'protocol'}      = 1 if($e->{'protocol'});
            $c{'portlist'}      = 1 if($e->{'portlist'});
            $c{'malware_hash'}  = 1 if($e->{'malware_hash'});
            $c{'rdata'}         = 1 if($e->{'rdata'});
            
            if($cfg_table_showmeta){
                $c{'asn'}                       = 1 if($e->{'asn'});
                $c{'asn_desc'}                  = 1 if($e->{'asn_desc'});
                $c{'prefix'}                    = 1 if($e->{'prefix'});
                $c{'cc'}                        = 1 if($e->{'cc'});
                $c{'rir'}                       = 1 if($e->{'rir'});
                $c{'malware_detection_rate'}    = 1 if($e->{'malware_detection_rate'});
            }
            # this could be a performance killer
            # work-around for searches that don't have
            # an address associated with it and would confuse
            # output
            $c{'address'}   = 1 if($e->{'description'} =~ /search $addr_regex$/);
        }
    }
    
    push(@cols,'address')       if($c{'address'});
    push(@cols,'rdata')         if($c{'rdata'});
    push(@cols,'malware_hash')  if($c{'malware_hash'});
    push(@cols,'prefix')        if($c{'prefix'});
    push(@cols,'hash')          if($c{'hash'} && !$c{'address'});
    push(@cols,'protocol')      if($c{'protocol'});
    push(@cols,'portlist')      if($c{'portlist'});

    ## TODO -- make these optional flags passed through
    ## table_showmeta or via the -f option
    if($cfg_table_showmeta && !$cfg_fields){
        push(@cols,'asn') if($c{'asn'});
        push(@cols,'asn_desc') if($c{'asn_desc'});
        push(@cols,'cc') if($c{'cc'});
        push(@cols,'rir') if($c{'rir'});
        push(@cols,'malware_detection_rate'), if($c{'malware_detection_rate'});
    }
    ## TODO -- malware hash lookups?
    
    push(@cols,(
        'alternativeid_restriction',
        'alternativeid',
    )) unless($cfg_fields);
    

    my @header = map { $_, { is_sep => 1, title => '|' } } @cols;
    pop(@header);
    my $table = Text::Table->new(@header);
    
    foreach my $e (@$array){
        # work-around for hash searches that don't show the address
        # at some point we'll move this back up the stack to Format.pm
        unless($e->{'address'}){
            for($e->{'description'}){
                if(/search ($addr_regex)$/){
                    $e->{'address'} = $1;
                    last;
                }
            }
        } else {
            if($cfg_compress_address && length($e->{'address'}) > 32){
                $e->{'address'} = substr($e->{'address'},0,31);
                $e->{'address'} .= '...';
            }
        }
        if($cfg_compress_address && length($e->{'description'}) > 32){
            $e->{'description'} = substr($e->{'description'},0,31);
            $e->{'description'} .= '...';
        }
        if($cfg_compress_address && $e->{'alternativeid'} && length($e->{'alternativeid'}) > 75){
            $e->{'alternativeid'} = substr($e->{'alternativeid'},0,74);
            $e->{'alternativeid'} = $e->{'alternativeid'} .= '...';
        }
        $table->load([ map { $e->{$_} } @cols]);
    }
    ## TODO -- what if RestrictionType in Iodef::Pb and FeedType get out of sync?
    my $restriction = $self->convert_restriction($args->{'restriction'}) || 'private';
    if($self->get_group_map && $self->get_group_map->{$args->{'guid'}}){
        $args->{'guid'} = $self->get_group_map->{$args->{'guid'}};
    }
    
    ## TODO - guid should be responded to by the router
    $args->{'uuid'}         = '' unless($args->{'uuid'});
    $args->{'guid'}         = '' unless($args->{'guid'});
    $args->{'description'}  = '' unless($args->{'description'});
    $args->{'reporttime'}   = '' unless($args->{'reporttime'});
    $args->{'confidence'}   = 0 unless($args->{'confidence'});
    
    my $limit = $args->{'limit'} || 0;
    
    my $meta = "feed description:   $args->{'description'}
feed reporttime:    $args->{'reporttime'}
feed uuid:          $args->{'uuid'}
feed guid:          $args->{'guid'}
feed restriction:   $restriction
feed confidence:    $args->{'confidence'}
feed limit:         $limit\n\n";

    unless($cfg_table_nowarning){
        $meta = 'WARNING: Turn off this warning by adding: \'table_nowarning = 1\' to your ~/.cif config'."\n\n".$meta;
        $meta = 'WARNING: This table output not to be used for parsing, see "-p plugins" (via cif -h)'."\n".$meta;
    }
    $table = $meta . $table;
    return $table;
}

1;