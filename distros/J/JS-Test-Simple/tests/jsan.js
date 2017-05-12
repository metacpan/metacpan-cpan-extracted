  JSAN.addRepository('../lib').use('Test.Builder');
  var test = new Test.Builder;
  if (Test.PLATFORM == 'director')
      test.plan({ skipAll: "JSAN not yet supporting Director" });
  else test.plan({ tests: 11 });
  var jsan = new JSAN;
  test.ok(jsan, "Instantiated JSAN object");
  test.ok(typeof Test.Simple == 'undefined',
          "Test.Simple should not yet be loaded");
  test.ok(typeof ok == 'undefined', "There should be no global ok");
  jsan.use('Test.Simple');
  test.ok(typeof Test.Simple != 'undefined',
          "Test.Simple should now be loaded");
  test.ok(typeof ok != 'undefined', "There should be now be a global ok");
  test.ok(ok == Test.Simple.ok,
          "The global ok should be the same as Test.Simple.ok");
  test.ok(plan == Test.Simple.plan,
          "The global plan should be the same as Test.Simple.plan");
  test.ok(typeof Test.More == 'undefined',
          "Test.More should not yet be loaded");
  test.ok(typeof isa == 'undefined', "There should be no global isa");
  jsan.use('Test.More');
  test.ok(typeof Test.More != 'undefined',
          "Test.More should now be loaded");
  test.ok(typeof isa != 'undefined', "There should now be a global isa");
