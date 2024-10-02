class CommandType
  VALUE = 0
  LOAD_LIBRARY = 1
  INVOKE_STATIC_METHOD = 2
  GET_STATIC_FIELD = 3
  SET_STATIC_FIELD = 4
  CREATE_CLASS_INSTANCE = 5
  GET_TYPE = 6
  REFERENCE = 7
  GET_MODULE = 8
  INVOKE_INSTANCE_METHOD = 9
  EXCEPTION = 10
  HEARTBEAT = 11
  CAST = 12
  GET_INSTANCE_FIELD = 13
  OPTIMIZE = 14
  GENERATE_LIB = 15
  INVOKE_GLOBAL_METHOD = 16
  DESTRUCT_REFERENCE = 17
  ARRAY_REFERENCE = 18
  ARRAY_GET_ITEM = 19
  ARRAY_GET_SIZE = 20
  ARRAY_GET_RANK = 21
  ARRAY_SET_ITEM = 22
  ARRAY = 23
  RETRIEVE_ARRAY = 24
  SET_INSTANCE_FIELD = 25
  INVOKE_GENERIC_STATIC_METHOD = 26
  INVOKE_GENERIC_METHOD = 27
  GET_ENUM_ITEM = 28
  GET_ENUM_NAME = 29
  GET_ENUM_VALUE = 30
  AS_REF = 31
  AS_OUT = 32
  GET_REF_VALUE = 33
  ENABLE_NAMESPACE = 34
  ENABLE_TYPE = 35
  CREATE_NULL = 36

  def self.get_name(command_number)
    case command_number
    when 0
      return 'VALUE'
    when 1
      return 'LOAD_LIBRARY'
    when 2
      return 'INVOKE_STATIC_METHOD'
    when 3
      return 'GET_STATIC_FIELD'
    when 4
      return 'SET_STATIC_FIELD'
    when 5
      return 'CREATE_CLASS_INSTANCE'
    when 6
      return 'GET_TYPE'
    when 7
      return 'REFERENCE'
    when 8
      return 'GET_MODULE'
    when 9
      return 'INVOKE_INSTANCE_METHOD'
    when 10
      return 'EXCEPTION'
    when 11
      return 'HEART_BEAT'
    when 12
      return 'CAST'
    when 13
      return 'GET_INSTANCE_FIELD'
    when 14
      return 'OPTIMIZE'
    when 15
      return 'GENERATE_LIB'
    when 16
      return 'INVOKE_GLOBAL_METHOD'
    when 17
      return 'DESTRUCT_REFERENCE'
    when 18
      return 'ARRAY_REFERENCE'
    when 19
      return 'ARRAY_GET_ITEM'
    when 20
      return 'ARRAY_GET_SIZE'
    when 21
      return 'ARRAY_GET_RANK'
    when 22
      return 'ARRAY_SET_ITEM'
    when 23
      return 'ARRAY'
    when 24
      return 'RETRIEVE_ARRAY'
    when 25
      return 'SET_INSTANCE_FIELD'
    when 26
      return 'INVOKE_GENERIC_STATIC_METHOD'
    when 27
      return 'INVOKE_GENERIC_METHOD'
    when 28
      return 'GET_ENUM_ITEM'
    when 29
      return 'GET_ENUM_NAME'
    when 30
      return 'GET_ENUM_VALUE'
    when 31
      return 'AS_REF'
    when 32
      return 'AS_OUT'
    when 33
      return 'GET_REF_VALUE'
    when 34
      return 'ENABLE_NAMESPACE'
    when 35
      return 'ENABLE_TYPE'
    when 36
      return 'CREATE_NULL'
    else
      raise 'Unknown command type'
    end
  end
end