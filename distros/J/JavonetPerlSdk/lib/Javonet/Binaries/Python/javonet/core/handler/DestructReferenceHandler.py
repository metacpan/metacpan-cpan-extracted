from javonet.core.referenceCache.ReferencesCache import ReferencesCache

from javonet.core.handler.AbstractCommandHandler import *


class DestructReferenceHandler(AbstractCommandHandler):
    def __init__(self):
        self._required_parameters_count = 1

    def process(self, command):
        reference_cache = ReferencesCache()
        return reference_cache.delete_reference(command.payload[0])

