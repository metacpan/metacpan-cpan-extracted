package Test::Google::RestApi::DriveApi3::Drive;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::DriveApi3::Drive';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub startup : Tests(startup) {
  my $self = shift;
  $self->SUPER::startup(@_);
  my @drives = mock_drive_api()->list_drives(max_pages => 1);
  if (@drives && $drives[0]->{id}) {
    $self->{_drive_id} = $drives[0]->{id};
  } else {
    $self->{_skip_drive_tests} = 1;
  }
  return;
}

sub _mock_drive {
  my ($self, %args) = @_;
  return Drive->new(
    drive_api => mock_drive_api(),
    id        => $self->{_drive_id} // 'drive123',
    %args,
  );
}

sub _constructor : Tests(3) {
  my $self = shift;

  ok my $drive = Drive->new(drive_api => mock_drive_api()),
    'Constructor without id should succeed';
  isa_ok $drive, Drive, 'Constructor returns';

  ok Drive->new(drive_api => mock_drive_api(), id => 'drive123'),
    'Constructor with id should succeed';

  return;
}

sub requires_id : Tests(5) {
  my $self = shift;

  my $drive = Drive->new(drive_api => mock_drive_api());

  throws_ok sub { $drive->get() },
    qr/Drive ID required/i,
    'get() without ID should throw';

  throws_ok sub { $drive->update(name => 'test') },
    qr/Drive ID required/i,
    'update() without ID should throw';

  throws_ok sub { $drive->delete() },
    qr/Drive ID required/i,
    'delete() without ID should throw';

  throws_ok sub { $drive->hide() },
    qr/Drive ID required/i,
    'hide() without ID should throw';

  throws_ok sub { $drive->unhide() },
    qr/Drive ID required/i,
    'unhide() without ID should throw';

  return;
}

sub accessors : Tests(2) {
  my $self = shift;

  my $drive = Drive->new(drive_api => mock_drive_api(), id => 'drive123');
  is $drive->drive_id(), 'drive123', 'drive_id returns correct ID';
  isa_ok $drive->drive_api(), 'Google::RestApi::DriveApi3', 'drive_api returns DriveApi3';

  return;
}

sub get_drive : Tests(2) {
  my $self = shift;

  SKIP: {
    skip "No shared drives available", 2 if $self->{_skip_drive_tests};

    my $drive = $self->_mock_drive();
    ok my $result = $drive->get(), 'get() returns result';
    ok $result->{id}, 'get() returns drive id';
  }

  return;
}

sub get_with_fields : Tests(1) {
  my $self = shift;

  SKIP: {
    skip "No shared drives available", 1 if $self->{_skip_drive_tests};

    my $drive = $self->_mock_drive();
    ok my $result = $drive->get(fields => 'name,id'), 'get() with fields returns result';
  }

  return;
}

sub get_with_domain_admin : Tests(1) {
  my $self = shift;

  SKIP: {
    skip "No shared drives available", 1 if $self->{_skip_drive_tests};

    my $drive = $self->_mock_drive();
    ok my $result = $drive->get(use_domain_admin_access => 1),
      'get() with use_domain_admin_access returns result';
  }

  return;
}

sub update_drive : Tests(1) {
  my $self = shift;

  SKIP: {
    skip "No shared drives available", 1 if $self->{_skip_drive_tests};

    my $drive = $self->_mock_drive();
    ok my $result = $drive->update(name => 'Renamed Drive'),
      'update() with name returns result';
  }

  return;
}

sub update_with_options : Tests(1) {
  my $self = shift;

  SKIP: {
    skip "No shared drives available", 1 if $self->{_skip_drive_tests};

    my $drive = $self->_mock_drive();
    ok my $result = $drive->update(
      name      => 'Styled Drive',
      color_rgb => '#FF0000',
      theme_id  => 'theme1',
      background_image_file => { id => 'img123' },
      restrictions => { adminManagedRestrictions => JSON::MaybeXS::true() },
      use_domain_admin_access => 1,
    ), 'update() with all options returns result';
  }

  return;
}

sub delete_drive : Tests(1) {
  my $self = shift;

  SKIP: {
    skip "No shared drives available", 1 if $self->{_skip_drive_tests};

    my $drive = $self->_mock_drive();
    lives_ok sub { $drive->delete() }, 'delete() lives';
  }

  return;
}

sub delete_with_options : Tests(1) {
  my $self = shift;

  SKIP: {
    skip "No shared drives available", 1 if $self->{_skip_drive_tests};

    my $drive = $self->_mock_drive();
    lives_ok sub {
      $drive->delete(
        use_domain_admin_access => 1,
        allow_item_deletion     => 1,
      )
    }, 'delete() with options lives';
  }

  return;
}

sub hide_drive : Tests(1) {
  my $self = shift;

  SKIP: {
    skip "No shared drives available", 1 if $self->{_skip_drive_tests};

    my $drive = $self->_mock_drive();
    ok my $result = $drive->hide(), 'hide() returns result';
  }

  return;
}

sub unhide_drive : Tests(1) {
  my $self = shift;

  SKIP: {
    skip "No shared drives available", 1 if $self->{_skip_drive_tests};

    my $drive = $self->_mock_drive();
    ok my $result = $drive->unhide(), 'unhide() returns result';
  }

  return;
}

1;
