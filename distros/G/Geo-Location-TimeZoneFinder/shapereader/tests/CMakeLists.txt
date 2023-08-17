set(tests
  byteorder
  dbase2
  dbf
  null
  point
  pointm
  pointz
  multipoint
  multipointm
  multipointz
  polyline
  polylinem
  polylinez
  polygon
  polygonm
  polygonz
  multipatch
)

foreach(name ${tests})
  add_executable(test_${name} test_${name}.c)
  target_link_libraries(test_${name} shapereader)
  add_test(NAME test_${name}
    COMMAND test_${name}
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/data"
  )
endforeach()

# Capture coverage data in lcov.info
add_custom_target(test-coverage
  COMMAND ${CMAKE_MAKE_PROGRAM} test
  COMMAND lcov -c -d CMakeFiles -o lcov.info
  BYPRODUCTS lcov.info
  WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
  VERBATIM
)
