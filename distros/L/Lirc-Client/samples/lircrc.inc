begin
  prog = lclient_test
  remote = son-cable
  button = CABLE_ENTER
  mode = enter_mode
end
begin enter_mode
    begin
      prog = lclient_test
      remote = son-cable
      button = CABLE_STOP
      config = ENTER_STOP
    end
    begin
      prog = lclient_test
      remote = son-cable
      button = CABLE_PLAY
      config = ENTER_PLAY
    end
end enter_mode

