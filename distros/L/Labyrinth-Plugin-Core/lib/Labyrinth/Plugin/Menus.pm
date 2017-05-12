package Labyrinth::Plugin::Menus;

use warnings;
use strict;

our $VERSION = '5.19';

=head1 NAME

Labyrinth::Plugin::Menus - Plugin Menus handler for Labyrinth

=head1 DESCRIPTION

Contains all the menu handling functionality for the Labyrinth
framework.

=cut

# menu array
# 0 = ?
# 1 = selected=1, unselected=0
# 2 = title
# 3 = href
# 4 = access
# 5 = text
# 6.. = images

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Audit;
use Labyrinth::Globals;
use Labyrinth::DBUtils;
use Labyrinth::Media;
use Labyrinth::MLUtils;
use Labyrinth::Session;
use Labyrinth::Support;
use Labyrinth::Variables;

# -------------------------------------
# Constants

use constant    MaxMenuWidth     => 400;
use constant    MaxMenuHeight    => 400;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    menuid      => { type => 0, html => 0 },
    name        => { type => 1, html => 1 },
    realmid     => { type => 1, html => 0 },
    typeid      => { type => 1, html => 0 },
    title       => { type => 0, html => 1 },
    parentid    => { type => 0, html => 0 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my @savefields  = qw(name title typeid realmid parentid);
my $INDEXKEY    = 'menuid';
my $ALLSQL      = 'AllMenus';
my $SAVESQL     = 'SaveMenu';
my $ADDSQL      = 'AddMenu';
my $GETSQL      = 'GetMenuByID';
my $DELETESQL   = 'DeleteMenu';
my $LEVEL       = ADMIN;

my %adddata = (
    menuid      => 0,
    realmid     => 0,
    type        => 0,
    title       => '',
    name        => '',
);


# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=head2 Default Methods

=over 4

=item LoadMenus

Loads all the menus used within the system, and stores them within the 'menu'
template variable hash, using the menuid as the key to each.

=back

=cut

sub LoadMenus {
    # get menu list for current realm
    my @rows = $dbi->GetQuery('hash','GetMenus',RealmID($tvars{realm}));

    $tvars{menus} = undef;  # in case we're reloading
    my $request = $ENV{REQUEST_URI};
    my $script = $settings{script};
    my (%match,%tree);
#    LogDebug("script=[$script]");

    # for each menu get option list
    for my $row (@rows) {
        $tvars{menus}->{$row->{menuid}}->{name}     = $row->{name};
        $tvars{menus}->{$row->{menuid}}->{title}    = $row->{title};
        $tvars{menus}->{$row->{menuid}}->{typeid}   = $row->{typeid};
        $tvars{menus}->{$row->{menuid}}->{parentid} = $row->{parentid};
        my @opts = $dbi->GetQuery('hash','GetOptions',$row->{menuid});
        for my $opt (@opts) {
            my @images;
            if($row->{typeid} > 1) {
                my @rs = $dbi->GetQuery('hash','GetOptImages',$opt->{optionid});
                @images = map {$_->{'link'}} @rs;
            }
#LogDebug("request=$request, opt=$opt->{href}");
#LogDebug("section=$tvars{section}, opt=$opt->{section}");
            # try and find the selected option
            my $inx = $tvars{menus}->{$row->{menuid}}->{data} ? scalar(@{$tvars{menus}->{$row->{menuid}}->{data}}) : 0;
            $match{request} = [$row->{menuid},$inx,$opt->{optionid}]    if($request && $request eq $opt->{href});
            $match{section} = [$row->{menuid},$inx,$opt->{optionid}]    if($opt->{section} && $tvars{section} eq $opt->{section});
            $match{options} = [$row->{menuid},$inx,$opt->{optionid}]    if($request && $request =~ /$opt->{href}/);
            $match{hideout} = [$row->{menuid},$inx,$opt->{optionid}]    if($opt->{section} && ($opt->{section} eq 'home' || $opt->{href} eq '/'));
            $match{default} = [$row->{menuid},$inx,$opt->{optionid}]    if(!$match{default});
            $opt->{href} =~ s!^\?!$script\?!;                       # all query only links are local
#            $opt->{href} =~ s!^/$script!$tvars{cgipath}/$script!;  # all script links are local
            push @{$tvars{menus}->{$row->{menuid}}->{data}},
                [   0,0,
                    $opt->{text},
                    $opt->{href},
                    ($opt->{accessid}||0),
                    $opt->{name},
                    @images
                ];
            $tree{$opt->{optionid}} = { menuid => $row->{menuid}, index => scalar(@{$tvars{menus}->{$row->{menuid}}->{data}}) - 1, parent => $row->{parentid} };
        }
    }

#LogDebug("match{$_}=$match{$_}[0]/$match{$_}[2]")    for(qw(request section options hideout default));

                             my $match = 'default';
       if($match{request}[0]) { $match = 'request'; }
    elsif($match{section}[0]) { $match = 'section'; }
    elsif($match{options}[0]) { $match = 'options'; }
    elsif($match{hideout}[0]) { $match = 'hideout'; }
    UpdateSession(optionid => $match{$match}->[2]);

    # previous/next trail
    $tvars{trail2}{prev} = _trail2($match{$match},-1);
    $tvars{trail2}{this} = _trail2($match{$match}, 0);
    $tvars{trail2}{next} = _trail2($match{$match}, 1);
    $tvars{trail1} = undef;

    # breadcrumbs trail
    my $menu = 0;
    my $opt = $match{$match}->[2];
    $tvars{menus}->{$tree{$opt}{menuid}}->{data}->[$tree{$opt}{index}][1] = 1;  # option has been selected

#    use Data::Dumper;
#    LogDebug("opt=$opt");
#    LogDebug("tree=".Dumper(\%tree));

    for(keys %tree) {
        next    unless(defined $opt && defined $tree{$_} && defined $tree{$_}->{parent});
        $menu = $tree{$_}->{menuid} if($opt == $tree{$_}->{parent});
    }

    while($opt) {
        $tvars{menus}->{$tree{$opt}{menuid}}->{data}->[$tree{$opt}{index}][0] = $menu;  # submenu has been selected
        push @{$tvars{trail1}},
        {
            text => $tvars{menus}->{$tree{$opt}{menuid}}->{data}->[$tree{$opt}{index}][2],
            href => $tvars{menus}->{$tree{$opt}{menuid}}->{data}->[$tree{$opt}{index}][3]
        };
        $menu = $tree{$opt}{menuid};
        $opt  = $tree{$opt}{parent};
    }
}

sub _trail2 {
    my ($hash,$diff) = @_;
    return  unless(defined $hash && @$hash);

    my %hash;
    my $opt = $hash->[1] + $diff;
    if($opt >= 0 && $opt < scalar(@{$tvars{menus}->{$hash->[0]}->{data}})) {
        $hash{text} = $tvars{menus}->{$hash->[0]}->{data}->[$opt][2];
        $hash{href} = $tvars{menus}->{$hash->[0]}->{data}->[$opt][3];
    }
    return \%hash;
}

sub _LoadMenus {
    # get menu list for current realm
    my @rows = $dbi->GetQuery('hash','GetMenus',RealmID($tvars{realm}));
    $tvars{menus} = undef;  # in case we're reloading
    my $request = $ENV{REQUEST_URI};
    my $script = $settings{script};
    my (%tree,$last,$href);
#    LogDebug("script=[$script]");

    # for each menu get option list
    for my $row (@rows) {
        $tvars{menus}->{$row->{menuid}}->{name}     = $row->{name};
        $tvars{menus}->{$row->{menuid}}->{title}    = $row->{title};
        $tvars{menus}->{$row->{menuid}}->{typeid}   = $row->{typeid};
        $tvars{menus}->{$row->{menuid}}->{parentid} = $row->{parentid};
        $last = '';
        $href = '';
        my @opts = $dbi->GetQuery('hash','GetOptions',$row->{menuid});
        for my $opt (@opts) {
            my @images;
            if($row->{typeid} > 1) {
                my @rs = $dbi->GetQuery('hash','GetOptImages',$opt->{optionid});
                @images = map {$_->{'link'}} @rs;
            }
            UpdateSession(optionid => $opt->{optionid})   if($request && $request =~ /$opt->{href}/);
            $opt->{href} =~ s!^\?!$script\?!;                       # all query only links are local
#            $opt->{href} =~ s!^/$script!$tvars{cgipath}/$script!;   # all script links are local

            # establish the current level trail
            if($tvars{trail2} && !$tvars{trail2}{'next'}) {
                $tvars{trail2}{'next'} = {text => $opt->{text}, href => $opt->{href}};
            }
            if($opt->{optionid} == $tvars{user}{option}) {
                $tvars{trail2} = {  'prev' => {text => $last, href => $href},
                                    'this' => {text => $opt->{text}}};
            } else {
                $last = $opt->{text};
                $href = $opt->{href};
            }
            push @{$tvars{menus}->{$row->{menuid}}->{data}}, [0,0,$opt->{text},$opt->{href},($opt->{accessid}||0),@images];

            $tree{$opt->{optionid}} = {
                minx => $row->{menuid},
                oinx => (scalar(@{$tvars{menus}->{$row->{menuid}}->{data}}) - 1),
                opar => $row->{parentid}
            };
        }
    }
#    use Data::Dumper;
#    LogDebug("LoadMenus: tree=".Dumper(\%tree));
    # now establish the main trail
    if($tvars{user}{option}) {
        my $option = $tvars{user}{option};
        for my $opt (keys %tree) {
            if($tree{$opt}->{opar} == $option) {
                $tvars{menus}{$tree{$option}->{minx}}{data}[$tree{$option}->{oinx}][0] = $tree{$opt}->{minx};
                LogDebug("LoadMenus: option=$option, opt=$opt, minx=$tree{$option}->{minx}, oinx=$tree{$option}->{oinx}, minx=$tree{$opt}->{minx}");
                                                                                # menu has a sub menu
                last;
            }
        }

        while($option) {
            my $minx = $tree{$option}->{minx};
            my $oinx = $tree{$option}->{oinx};
            if($minx && $oinx) {
                $tvars{menus}{$minx}{data}[$oinx][1] = 1;                        # menu has been selected
                unshift @{$tvars{trail1}},                                      # breadcrumbs trail
                            {text => $tvars{menus}{$minx}{data}[$oinx][2],
                             href => $tvars{menus}{$minx}{data}[$oinx][3]};
            }
            $option = $tree{$option}->{opar};
            next    unless($option);
            my $pinx = $tree{$option}->{minx};
               $oinx = $tree{$option}->{oinx};
            $tvars{menus}{$pinx}{data}[$oinx][0] = $minx;                       # menu has this sub menu
        }
    }
}

=head1 ADMIN INTERFACE METHODS

=head2 Menu Methods

=over

=item Admin

List current menus.

=item Add

Add a new menu.

=item Edit

Edit a given menu.

=item Save

Save the given menu.

=item Delete

Delete the given menu.

=item DeleteOptions

Delete the specified option(s) of a given menu.

=item TypeSelect

Provide a drop down list of menu option types.

=item TypeName

Provide the name of the given option type.

=item ParentSelect

Provides a drop down in order to enable multiple levels of menus and options.

=item CheckImages

Stores the image for a menu option state.

=back

=cut

sub Admin {
    return  unless(AccessUser($LEVEL));

    if($cgiparams{doaction}) {
           if($cgiparams{doaction} eq 'Delete' ) { Delete();  }
    }

    my @rows = $dbi->GetQuery('hash',$ALLSQL);
    for (@rows) {
        $_->{type} = TypeName($_->{typeid});
        $_->{realm} = RealmName($_->{realmid});
    }
    $tvars{data} = \@rows   if(@rows);
}

sub Add {
    return  unless AccessUser($LEVEL);
    $tvars{data} = \%adddata;
    $tvars{data}->{ddtypes}  = TypeSelect();
    $tvars{data}->{ddrealms} = RealmSelect();
    $tvars{data}->{ddparent} = ParentSelect();
}

sub Edit {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);

    my $script = $settings{script};

    my @opts = $dbi->GetQuery('hash','GetOptions',$tvars{data}->{menuid});
    for my $opt (@opts) {
        my @images;
        if($tvars{data}->{typeid} > 1) {
            my @rs = $dbi->GetQuery('hash','GetOptImages',$opt->{optionid});
            for(@rs) {
                $opt->{'image' . $_->{typeid}} = $_->{'link'};
                $opt->{'imageid' . $_->{typeid}} = $_->{'imageid'};
            }
            @images = map {$_->{'link'}} @rs;
        }
        $opt->{ddaccess} = AccessSelect($opt->{accessid},'ACCESS'.$opt->{optionid});

        my $href = $opt->{href};
        $href =~ s!^\?!$script\?!;                       # all query only links are local
        push @{$tvars{preview}->{data}}, [0,0,$opt->{text},$href,($opt->{accessid}||0),$opt->{name},@images];
    }
    $tvars{data}->{options}  = \@opts   if(@opts);
    $tvars{data}->{ddtypes}  = TypeSelect($tvars{data}->{typeid});
    $tvars{data}->{ddrealms} = RealmSelect($tvars{data}->{realmid});
    $tvars{data}->{ddparent} = ParentSelect($tvars{data}->{parentid},$tvars{data}->{menuid});

    $tvars{preview}->{$_} = $tvars{data}->{$_}    for(qw(title typeid parentid));
}

sub Save {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);

    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }

    return  if FieldCheck(\@allfields,\@mandatory);

    my @fields = map {$tvars{data}->{$_}} @savefields;
    if($cgiparams{$INDEXKEY}) {
        $dbi->DoQuery($SAVESQL,@fields,$cgiparams{$INDEXKEY});
    } else {
        $cgiparams{$INDEXKEY} = $dbi->IDQuery($ADDSQL,@fields);
    }

    # delete option if requested
    if($cgiparams{'doaction'}) {
        DeleteOptions()    if($cgiparams{'doaction'} eq 'DeleteOption');
    }

    # save options
    my $order = 1;
    my @opts = $dbi->GetQuery('hash','GetOptions',$tvars{data}->{menuid});
    for my $opt (@opts) {
        my @fields = (
            $cgiparams{"ORDER"    . $opt->{optionid}},          # menu order
            $cgiparams{"NAME"     . $opt->{optionid}},          # CSS code name
            $cgiparams{"SECT"     . $opt->{optionid}},          # section name
            $cgiparams{"TEXT"     . $opt->{optionid}},          # menu text
            $cgiparams{"HREF"     . $opt->{optionid}},          # menu link
            ($cgiparams{"ACCESS"  . $opt->{optionid}} || 0),    # access level
        );
        $dbi->DoQuery('SaveOption',@fields,$opt->{optionid});
        $order = $opt->{orderno} + 1;

        my @rs = $dbi->GetQuery('hash','GetOptImages',$opt->{optionid});
        my %images = map {$_->{typeid} => $_->{imageid}} @rs;
        CheckImages($images{1},'IMAGEFILE',$opt->{optionid},1)  if($tvars{data}->{typeid} > 1);
        CheckImages($images{2},'ROLLOVER' ,$opt->{optionid},2)  if($tvars{data}->{typeid} > 2);
        CheckImages($images{3},'SELECTED' ,$opt->{optionid},3)  if($tvars{data}->{typeid} > 3);
    }

    # add option if requested
    if($cgiparams{'doaction'}) {
        $dbi->DoQuery('AddOption',$tvars{data}->{menuid},$order,0)  if($cgiparams{'doaction'} eq 'AddOption');
    }

    $tvars{thanks} = 1;
}

sub Delete {
    return  unless AccessUser($LEVEL);
    my @ids = CGIArray('LISTED');
    return  unless @ids;

    # remove menus
    my $ids = join(",",@ids);
    $dbi->DoQuery($DELETESQL,{ids=>$ids});
    my @opts = $dbi->GetQuery('hash','FindOptions',{ids=>$ids});

    # remove options
    $ids = join(",",map {$_->{optionid}} @opts);
    $dbi->DoQuery('DeleteOptions',{ids=>$ids});
    $dbi->DoQuery('DeleteOptImages',{ids=>$ids});
}

sub DeleteOptions {
    my @ids = CGIArray('LISTED');
    return  unless @ids;
    my $ids = join(",",@ids);
    $dbi->DoQuery('DeleteOptions',{ids=>$ids});
    $dbi->DoQuery('DeleteOptImages',{ids=>$ids});
}

my %types = (
    1 => 'text',
    2 => 'image',
    3 => 'rollover',
    4 => 'highlighted',
);
my @types = map {{'id'=>$_,'value'=> $types{$_}}} sort keys %types;

sub TypeSelect {
    my $opt = shift || 0;
    DropDownRows($opt,"typeid",'id','value',@types);
}

sub TypeName {
    my $id = shift || 1;
    return $types{$id};
}

sub ParentSelect {
    my $oinx = shift || 0;
    my $minx = shift || 0;
    my @opts = $dbi->GetQuery('hash','GetAllOptions',$minx);
    my @rows = map {{optionid => $_->{optionid}, text => "$_->{name} - $_->{text}"}} @opts;
    unshift @rows, {optionid => 0, text => 'Select Parent Option'};
    DropDownRows($oinx,"parentid",'optionid','text',@rows);
}

sub CheckImages {
    my ($oldid,$key,$optionid,$typeid) = @_;
    my $param = $key . $optionid;

    return unless($cgiparams{$param});

    my $maximagewidth  = $settings{maxmenuwidth}  || MaxMenuWidth;
    my $maximageheight = $settings{maxmenuheight} || MaxMenuHeight;

#    my $file = CGIFile($key . $optionid);
    my ($imageid) = SaveImageFile(
            param => $key . $optionid,
            stock => 'DRAFT'
        );

    my $sqlkey = ($oldid ? 'SaveOptImage' : 'AddOptImage');
    $dbi->DoQuery($sqlkey,$imageid,$optionid,$typeid);
}

1;

__END__

=head1 SEE ALSO

L<Labyrinth>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
