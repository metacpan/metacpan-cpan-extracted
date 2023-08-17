cmake_minimum_required(VERSION 3.4)

set(CPACK_PACKAGE_VERSION_MAJOR 0)
set(CPACK_PACKAGE_VERSION_MINOR 0)
set(CPACK_PACKAGE_VERSION_PATCH 1)

string(CONCAT version
  "${CPACK_PACKAGE_VERSION_MAJOR}"
  "."
  "${CPACK_PACKAGE_VERSION_MINOR}"
  "."
  "${CPACK_PACKAGE_VERSION_PATCH}"
)

project(shapereader
  LANGUAGES C
  VERSION ${version}
)

string(CONCAT description
  "A C library for reading ESRI shapefiles. The shapefile format is a geospatial\n"
  "vector data format for geographic information system software."
)

set(libshapereader_a_SOURCES
  dbf.c
  shp-multipatch.c
  shp-multipoint.c
  shp-multipointm.c
  shp-multipointz.c
  shp-point.c
  shp-polygon.c
  shp-polygonm.c
  shp-polygonz.c
  shp-polyline.c
  shp-polylinem.c
  shp-polylinez.c
  shp.c
  shx.c
)

set(pkginclude_HEADERS
  dbf.h
  shp-multipatch.h
  shp-multipoint.h
  shp-multipointm.h
  shp-multipointz.h
  shp-point.h
  shp-pointm.h
  shp-pointz.h
  shp-polygon.h
  shp-polygonm.h
  shp-polygonz.h
  shp-polyline.h
  shp-polylinem.h
  shp-polylinez.h
  shp.h
  shx.h
  shapereader.h
)

add_library(shapereader STATIC
  ${libshapereader_a_SOURCES}
)

set_target_properties(shapereader PROPERTIES
  PUBLIC_HEADER "${pkginclude_HEADERS}"
)

include(TestBigEndian)
test_big_endian(WORDS_BIGENDIAN)
if(WORDS_BIGENDIAN)
  add_definitions(-DWORDS_BIGENDIAN=1)
endif()

include(CTest)
add_subdirectory(tests)

include(GNUInstallDirs)

install(TARGETS shapereader
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/shapereader
)

# Create shapereader.pc for pkg-config
set(prefix ${CMAKE_INSTALL_PREFIX})
set(exec_prefix \${prefix})
set(libdir \${exec_prefix}/${CMAKE_INSTALL_LIBDIR})
set(includedir \${prefix}/${CMAKE_INSTALL_INCLUDEDIR})
set(PACKAGE_VERSION ${version})

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/shapereader.pc.in
  ${CMAKE_CURRENT_BINARY_DIR}/shapereader.pc
  @ONLY
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/shapereader.pc
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)

# Configure cpack
if(NOT DEFINED CPACK_PACKAGE_CONTACT)
  if((DEFINED ENV{DEBFULLNAME}) AND (DEFINED ENV{DEBEMAIL}))
    set(CPACK_PACKAGE_CONTACT "$ENV{DEBFULLNAME} <$ENV{DEBEMAIL}>")
  endif()
endif()

set(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_BINARY_DIR}/Description.txt")
file(WRITE ${CPACK_PACKAGE_DESCRIPTION_FILE} ${description})

set(CPACK_PACKAGE_NAME "libshapereader-devel")
set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${version}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Library for reading ESRI shapefiles")
set(CPACK_DEBIAN_PACKAGE_NAME "libshapereader-dev")
set(CPACK_DEBIAN_PACKAGE_RELEASE 1)
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libc6-dev | libc-dev")
set(CPACK_DEBIAN_PACKAGE_SUGGESTS "pkg-config")
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
set(CPACK_RPM_PACKAGE_LICENSE "ISC")
set(CPACK_GENERATOR "ZIP")
set(CPACK_SOURCE_GENERATOR "ZIP")
set(CPACK_SOURCE_IGNORE_FILES
  \\.git/
  build/
  ".*~$"
  "\\.swp$"
)
set(CPACK_VERBATIM_VARIABLES YES)
include(CPack)

# Format the source code files with clang-format
file(GLOB all_SOURCES
  RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
  *.[ch]
  tests/*.[ch]
)
add_custom_target(clang-format
  COMMAND clang-format --verbose -style=file -i ${all_SOURCES}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  VERBATIM
)
